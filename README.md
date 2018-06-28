# fluent-plugin-application-insights-parser

This is the [Fluentd](https://fluentd.org/) parser plugin for [Azure Application Insights](https://docs.microsoft.com/azure/application-insights/).  
It is intended to be used together with the Http input plugin, so the Application Insights SDKs can send telemetries to the fluentd agent by overriding the endpoint address.

## Installation

```
$ gem install fluent-plugin-application-insights-parser
```

## Configuration

```
<source>
  @type http
  <parse>
    @type application_insights
  </parse>
</source>
```

NOTE: Before this [fix](https://github.com/fluent/fluentd/commit/048d30f1f65bbcb3f8ff52e5d2989b6b5ddd2482) of fluentd Http plugin is released, you need to set the time_key of the parser to nil. Otherwise, the record will get lost.

```
<source>
  @type http
  <parse>
    @type application_insights
    time_key nil
  </parse>
</source>
```

## Contributing
Refer to [Contributing Guide](CONTRIBUTING.md).

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
