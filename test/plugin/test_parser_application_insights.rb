require 'helper'
require 'json'
require 'fluent/plugin/parser_application_insights'

class ApplicationInsightsParserTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
  ]

  def compress(data)
    data = JSON.generate(data) if data.is_a? Hash
    wio = StringIO.new("w")
    w_gz = Zlib::GzipWriter.new wio, nil, nil
    w_gz.write(data)
    w_gz.close
    wio.string
  end

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Parser.new(Fluent::Plugin::ApplicationInsightsParser).configure(conf)
  end

  sub_test_case 'decompress' do
    test 'gzip stream are decompressed successfully' do
      driver = create_driver
      data = { "prop" => "value" }
      decompressed = driver.instance.decompress(compress(data))
      assert_equal JSON.generate(data), decompressed
    end

    test 'return original text if gzip decompress failed' do
      driver = create_driver
      data = "plain text"
      decompressed = driver.instance.decompress(compress(data))
      assert_equal data, decompressed
    end
  end

  test 'input is empty string' do
    driver = create_driver
    driver.instance.parse("") do |time, record|
      assert_equal nil, time
      assert_equal nil, record

      logs = driver.instance.log.out.logs
      assert_equal 0, logs.length
    end
  end

  test 'input is invalid json' do
    driver = create_driver
    text = compress("invalid")
    driver.instance.parse(text) do |time, record|
      assert_equal nil, time
      assert_equal nil, record

      logs = driver.instance.log.out.logs
      assert_equal 1, logs.length
      assert_true logs.all?{ |log| log.include?("Failed to parse") }
    end
  end

  test 'input is single json object in multiline format' do
    driver = create_driver
    data = { "prop" => "value" }
    pretty_json = JSON.pretty_generate(data)

    driver.instance.parse(compress(pretty_json)) do |time, record|
      assert_equal nil, time
      assert_equal nil, record

      # It's expected to fail for single json object in multiline format as we want to support multi json objects that are line separated
      logs = driver.instance.log.out.logs
      assert_equal 1, logs.length
      assert_true logs.all?{ |log| log.include?("Failed to parse") }
    end
  end

  test 'parse single telemetry' do
    driver = create_driver
    data = { "prop" => "value", "time" => "2018-06-25T00:24:00.5676240Z" }
    driver.instance.parse(compress(data)) do |time, record|
      assert_equal Fluent::EventTime.from_time(Time.iso8601("2018-06-25T00:24:00.5676240Z")), time
      assert_equal({ "prop" => "value" }, record)
    end
  end

  test 'parse empty json array' do
    driver = create_driver
    driver.instance.parse(compress([])) do |time, record|
      assert_not_equal nil, time
      assert_true record.is_a?(Array) && record.length == 0
    end
  end

  test 'parse multiple telemetries as json array' do
    driver = create_driver
    data1 = { "prop1" => "value1" }
    data2 = { "prop2" => "value2" }
    driver.instance.parse(compress(JSON.generate([data1, data2]))) do |time, record|
      assert_not_equal nil, time
      assert_true record.is_a?(Array) && record.length == 2
      assert_equal data1, record[0]
      assert_equal data2, record[1]
    end
  end

  sub_test_case 'parse multiple telemetries as line separated json objects' do
    test 'LF as newline' do
      driver = create_driver
      data1 = { "prop1" => "value1" }
      data2 = { "prop2" => "value2" }
      text = JSON.generate(data1) + "\n" + JSON.generate(data2)
      driver.instance.parse(compress(text)) do |time, record|
        assert_not_equal nil, time
        assert_true record.is_a?(Array) && record.length == 2
        assert_equal data1, record[0]
        assert_equal data2, record[1]
      end
    end

    test 'CRLF as newline' do
      driver = create_driver
      data1 = { "prop1" => "value1" }
      data2 = { "prop2" => "value2" }
      text = JSON.generate(data1) + "\r\n" + JSON.generate(data2)
      driver.instance.parse(compress(text)) do |time, record|
        assert_not_equal nil, time
        assert_true record.is_a?(Array) && record.length == 2
        assert_equal data1, record[0]
        assert_equal data2, record[1]
      end
    end
  end
end
