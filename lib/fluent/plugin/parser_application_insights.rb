# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

require 'fluent/plugin/parser'
require 'fluent/env'
require 'fluent/time'

require 'yajl'
require 'json'

module Fluent
  module Plugin
    class ApplicationInsightsParser < Parser
      Plugin.register_parser('application_insights', self)

      config_set_default :time_key, 'time'
      config_set_default :time_type, :string
      config_set_default :time_format, '%iso8601'

      desc 'Set JSON parser'
      config_param :json_parser, :enum, list: [:oj, :yajl, :json], default: :oj

      def configure(conf)
        if conf.has_key?('time_format')
          conf['time_type'] ||= 'string'
        end

        super
        @load_proc, @error_class = configure_json_parser(@json_parser)
      end

      def configure_json_parser(name)
        case name
        when :oj
          require 'oj'
          Oj.default_options = Fluent::DEFAULT_OJ_OPTIONS
          [Oj.method(:load), Oj::ParseError]
        when :json then [JSON.method(:load), JSON::ParserError]
        when :yajl then [Yajl.method(:load), Yajl::ParseError]
        else
          raise "BUG: unknown json parser specified: #{name}"
        end
      rescue LoadError
        name = :yajl
        log.info "Oj is not installed, and failing back to Yajl for json parser" if log
        retry
      end

      def parse(text)
        decompressed = decompress(text)

        if decompressed.start_with?('[') && decompressed.end_with?(']')
          records = @load_proc.call(decompressed)
          yield parse_time(records[0]), records
        else
          splits = decompressed.split(/\r?\n/)
          if splits.length == 0
            yield nil, nil
          elsif splits.length == 1
            record = @load_proc.call(splits[0])
            yield parse_time(record), record
          else
            records = []
            splits.each do |line|
              records.push(@load_proc.call(line))
            end
            yield parse_time(records[0]), records
          end
        end
      rescue @error_class, EncodingError # EncodingError is for oj 3.x or later
        log.warn "Failed to parse #{text}. The input must be gziped or plain text of json object, array of json objects or line separated json objects"
        yield nil, nil
      end

      def parser_type
        :binary
      end

      def decompress(data)
        io = StringIO.new(data, "rb")
        gz = Zlib::GzipReader.new(io)
        gz.read
      rescue
        data
      end
    end
  end
end
