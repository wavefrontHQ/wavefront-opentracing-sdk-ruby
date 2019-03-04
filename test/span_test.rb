require 'test_helper'
require_relative '../lib/wavefrontopentracing/tracer'
require_relative '../lib/wavefrontopentracing/reporting/console'
require_relative '../util/application_tags'

class SpanTest < Minitest::Test

  def self.app_tags
    Wavefront::ApplicationTags.new("app",
                                   "service",
                                   cluster: "us-west-1",
                                   shard: "primary",
                                   custom_tags: {"custom_k" => "custom_v"})
  end

  # Test Ignore Active Span.
  def test_ignore_active_span
    tracer = WavefrontOpentracing::Tracer.new(Reporting::ConsoleReporter.new, SpanTest.app_tags)
    scope = tracer.start_active_span('test_op')
    assert scope
    active_span = scope.span
    # Span created with ignore_active_span = false by default.
    child_span = tracer.start_span("child_op",
                                   child_of: active_span,
                                   ignore_active_span: false)
    active_trace_id = active_span.trace_id.to_s
    child_trace_id = child_span.trace_id.to_s
    assert_equal active_trace_id, child_trace_id
    child_span.finish
    # Span created with ignore_active_span = true.
    child_span = tracer.start_span("child_op",
                                   ignore_active_span: true)
    active_trace_id = active_span.trace_id.to_s
    child_trace_id = child_span.trace_id.to_s
    refute_match active_trace_id, child_trace_id
    child_span.finish

    scope.close
    tracer.close
  end

  # test Multi-valued Tags.
  def test_multi_valued_tags
    tracer = WavefrontOpentracing::Tracer.new(Reporting::ConsoleReporter.new, SpanTest.app_tags)
    span = tracer.start_span("test_op", tags: {"key1" => "val1", "key2" => "val2"})
    assert span
    assert span.tags
    assert span.get_tags_as_list
    assert span.get_tags_as_map
    assert_equal 7, span.get_tags_as_map.length
    assert "app", span.get_tags_as_map["application"]
    assert "service", span.get_tags_as_map["service"]
    assert "us-west-1", span.get_tags_as_map["cluster"]
    assert "primary", span.get_tags_as_map["shard"]
    assert "custom_v", span.get_tags_as_map["custom_k"]
    assert "val1", span.get_tags_as_map["key1"]
    assert "val2", span.get_tags_as_map["key2"]
    span.finish
    tracer.close
  end
end
