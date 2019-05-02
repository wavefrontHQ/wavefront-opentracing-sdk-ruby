# wavefront-opentracing-sdk-ruby [![travis build status](https://travis-ci.com/wavefrontHQ/wavefront-opentracing-sdk-ruby.svg?branch=master)](https://travis-ci.com/wavefrontHQ/wavefront-opentracing-sdk-ruby) [![OpenTracing Badge](https://img.shields.io/badge/OpenTracing-enabled-blue.svg)](https://opentracing.io)

The Wavefront by VMware OpenTracing SDK for Ruby is a library that provides open tracing support for Wavefront.

## Requirements and Installation

Ruby 2.6 and above are supported.

```bash
gem install wavefront-opentracing-sdk 
```
## Set Up a Tracer

[Tracer](https://github.com/opentracing/specification/blob/master/specification.md#tracer) is an OpenTracing [interface](https://github.com/opentracing/opentracing-java#initialization) for creating spans and propagating them across arbitrary transports.

This SDK provides a `WavefrontTracer` for creating spans and sending them to Wavefront. The steps for creating a `WavefrontTracer` are:
1. Create an `ApplicationTags` instance, which specifies metadata about your application.
2. Create a Wavefront sender object for sending trace data to Wavefront.
3. Create a `WavefrontSpanReporter` for reporting trace data to Wavefront.
4. Create the Wavefront `Tracer` instance.

The following code sample creates a Tracer. For the details of each step, see the sections below.

```ruby
tracer = WavefrontOpentracing::Tracer.new(reporter, application_tags, global_tags)
```

### 1. Set Up Application Tags

Application tags determine the metadata (span tags) that are included with every span reported to Wavefront. These tags enable you to filter and query trace data in Wavefront. 

You encapsulate application tags in an `ApplicationTags` object.

### 2. Set Up a Wavefront Sender

A "Wavefront sender" is an object that implements the low-level interface for sending data to Wavefront. You can choose to send data using either the [Wavefront proxy](https://docs.wavefront.com/proxies.html) or [direct ingestion](https://docs.wavefront.com/direct_ingestion.html).

* If you have already set up a Wavefront sender for another SDK that will run in the same process, use that one.

* Otherwise, follow the steps in [Set Up a Wavefront Sender](https://github.com/wavefrontHQ/wavefront-sdk-ruby#set-up-a-wavefront-client).

### 3. Set Up a Reporter

You must create a `WavefrontSpanReporter` to report trace data to Wavefront. You can optionally create a `CompositeReporter` to send data to Wavefront and to print to the console.

#### Create a WavefrontSpanReporter

To create a `WavefrontSpanReporter`: 

* Specify the Wavefront sender from [Step 2](#2-set-up-a-wavefront-sender), i.e. either `WavefrontProxyClient` or `WavefrontDirectClient`.

* (Optional) Specify a string that represents the source for the reported spans. If you omit the source, the host name is automatically used.

To create a `WavefrontSpanReporter`:

```ruby
require 'wavefrontopentracing'
require 'wavefront/client/direct'
# or
# require 'wavefront/client/proxy'

# Wavefront sender for direct ingestion
wavefront_sender = Wavefront::WavefrontDirectIngestionClient.new('<wavefront-cluster>', '<API-Token>')
# or
# Wavefront sender for proxy
# default values: metrics_port = 2878, distribution_port = 2878, tracing_port = 30000
# wavefront_sender = Wavefront::WavefrontProxyClient.new(<proxy_host_ip>, metrics_port, distribution_port, tracing_port)

wf_span_reporter = WavefrontSpanReporter(
    client: wavefront_sender,
    source: "wavefront-tracing-example"   # optional nondefault source name
)

# To get failures observed while reporting.
total_failures = wf_span_reporter.failure_count()
```
**Note:** After you initialize the Wavefront `Tracer` with the `WavefrontSpanReporter` (in step 4), completed spans will automatically be reported to Wavefront.
You do not need to start the reporter explicitly.

#### Create a CompositeReporter (Optional)

A `CompositeReporter` enables you to chain a `WavefrontSpanReporter` to another reporter, such as a `ConsoleReporter`. A console reporter is useful for debugging.

```ruby
require 'wavefrontopentracing'

wf_span_reporter = ...   

# Create a console reporter that reports span to stdout
console_reporter = ConsoleReporter(source="wavefront-tracing-example")

# Instantiate a composite reporter composed of console and WavefrontSpanReporter.
composite_reporter = CompositeReporter(wf_span_reporter, console_reporter)
```

### 4. Create the Wavefront Tracer

To create a Wavefront `Tracer`, you pass the `ApplicationTags` and `Reporter` instances you created in the previous steps:

```ruby
require 'wavefrontopentracing'
require 'wavefront/client/common/application_tags'
require 'wavefront/client/direct'
# or
# require 'wavefront/client/proxy'

application_tags = ...   # see Step 1 above
wf_span_reporter = ...   # see Step 3 above

# Construct Wavefront opentracing Tracer
tracer = WavefrontOpentracing::Tracer.new(reporter=wf_span_reporter,
                                          application_tags=application_tags) 
```

#### Close the Tracer

Always close the tracer before exiting your application to flush all buffered spans to Wavefront.

```ruby
tracer.close()
```
## Cross Process Context Propagation

See the [context propagation documentation](https://github.com/wavefrontHQ/wavefront-opentracing-sdk-ruby/tree/master/docs/contextpropagation.md) for details on propagating span contexts across process boundaries.

## RED Metrics

See the [RED metrics documentation](https://github.com/wavefrontHQ/wavefront-opentracing-sdk-ruby/blob/master/docs/metrics.md) for details on the out-of-the-box metrics and histograms that are provided.
