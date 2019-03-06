require 'test_helper'
require 'wavefront/client'
require_relative '../lib/wavefrontopentracing/reporting/wavefront'
require_relative '../lib/wavefrontopentracing/reporting/console'
require_relative '../lib/wavefrontopentracing/reporting/composite'
require_relative '../lib/wavefrontopentracing/tracer'
require_relative '../lib/wavefrontopentracing/span'

class ReporterTest < Minitest::Test

  def self.app_tags
    Wavefront::ApplicationTags.new("wft2-shopping",
                                   "shopping-service",
                                   cluster: "virunga",
                                   shard: "shopping-shard",
                                   custom_tags: {"size" => "XL", "color" => "black"})
  end

  def test_composite_reporter
    proxy_host = '10.192.167.61'
    metrics_port = 2878
    distribution_port = 40000
    tracing_port = 30000

    reporter = []
    # create composite reporter to include proxy reporter, direct ingestion
    #   reporter and console reporter. Report span data to all the reporters.
    proxy_client = Wavefront::WavefrontProxyClient.new(proxy_host,
                                                       metrics_port,
                                                       distribution_port,
                                                       tracing_port)
    preporter = Reporting::WavefrontSpanReporter.new(client: proxy_client,
                                                       source: "proxy")

    direct_client = Wavefront::WavefrontDirectIngestionClient.new(
                      'https://nimba.wavefront.com',
                      '41012cb0-b65c-4f99-997d-c56da68833af')

    dreporter = Reporting::WavefrontSpanReporter.new(client: direct_client,
                                                       source: "direct")
    creporter = Reporting::ConsoleReporter.new(source: "reporter_tester")
    composite_reporter = Reporting::CompositeReporter.new(preporter,
                                                          dreporter,
                                                          creporter)
    assert composite_reporter
    tracer = WavefrontOpentracing::Tracer.new(composite_reporter,
                                              ReporterTest.app_tags)
    scope = tracer.start_active_span('test_op')
    assert scope
    active_span = scope.span
    child_span = tracer.start_span("child_op",
                                   child_of: active_span,
                                   ignore_active_span: false)
    active_trace_id = active_span.trace_id.to_s
    child_trace_id = child_span.trace_id.to_s
    assert_equal active_trace_id, child_trace_id
    composite_reporter.report(child_span)
    assert composite_reporter.failure_count
    child_span.finish
    composite_reporter.report(active_span)
    assert composite_reporter.failure_count
    scope.close
    tracer.close
  end
end
