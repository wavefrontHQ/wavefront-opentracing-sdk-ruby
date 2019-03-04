require 'test_helper'
require_relative '../lib/wavefrontopentracing/tracer'
require_relative '../lib/wavefrontopentracing/reporting/console'
require_relative '../util/application_tags'

class TracerTest < Minitest::Test

  def self.app_tags
    Wavefront::ApplicationTags.new("app",
                                   "service",
                                   cluster: "us-west-1",
                                   shard: "primary",
                                   custom_tags: {"custom_k" => "custom_v"})
  end

  # Test tracer inject and extract functionalities
  def test_inject_extract
    tracer = WavefrontOpentracing::Tracer.new(Reporting::ConsoleReporter.new, TracerTest.app_tags)
    span = tracer.start_span('test_tracer')
    assert span
    span.set_baggage_item("customer", "test_customer")
    span.set_baggage_item("request_type", "mobile")
    carrier = {}
    tracer.inject(span.context, OpenTracing::FORMAT_TEXT_MAP, carrier)
    span.finish
    ctx = tracer.extract(OpenTracing::FORMAT_TEXT_MAP, carrier)
    assert_equal("test_customer", ctx.get_baggage_item("customer"))
    assert_equal("mobile", ctx.get_baggage_item("request_type"))
  end

  # Test Active Span.
  def test_active_span
    tracer = WavefrontOpentracing::Tracer.new(Reporting::ConsoleReporter.new, TracerTest.app_tags)
    span = tracer.start_span("test_op_1")
    assert span
    span.finish
    scope = tracer.start_active_span("test_op_2", finish_on_close: true)
    assert scope
    assert scope.span
    assert_nil scope.close
  end

  # Test Global Tags.
  def test_global_tags
    global_tags = {"foo1" => "bar1", "foo2" => "bar2"}
    tracer = WavefrontOpentracing::Tracer.new(Reporting::ConsoleReporter.new, TracerTest.app_tags, global_tags)
    span = tracer.start_span("test_op" , tags: {"foo3" => "bar3"})
    assert span
    assert span.tags
    assert span.get_tags_as_list
    assert span.get_tags_as_map
    assert_equal 8, span.tags.length
    assert_equal 8, span.get_tags_as_map.length
    assert_equal "app", span.get_tags_as_map["application"]
    assert_equal "service", span.get_tags_as_map["service"]
    assert_equal "us-west-1", span.get_tags_as_map["cluster"]
    assert_equal "primary", span.get_tags_as_map["shard"]
    assert_equal "custom_v", span.get_tags_as_map["custom_k"]
    assert_equal "bar1", span.get_tags_as_map["foo1"]
    assert_equal "bar2", span.get_tags_as_map["foo2"]
    assert_equal "bar3", span.get_tags_as_map["foo3"]
    span.finish
    tracer.close
  end

  # Test Global Multi-valued Tags.
  def test_global_multi_valued_tags
    global_tags = {"key1" => "val1", "key1" => "val2"}
    tracer = WavefrontOpentracing::Tracer.new(Reporting::ConsoleReporter.new, TracerTest.app_tags, global_tags)
    span = tracer.start_span("test_op")
    assert span
    assert span.tags
    assert span.get_tags_as_map
    assert_equal 6, span.tags.length
    assert_equal 6, span.get_tags_as_map.length
    assert_equal "app", span.get_tags_as_map["application"]
    assert_equal "service", span.get_tags_as_map["service"]
    assert_equal "us-west-1", span.get_tags_as_map["cluster"]
    assert_equal "primary", span.get_tags_as_map["shard"]
    assert_equal "custom_v", span.get_tags_as_map["custom_k"]
    assert_equal "val2", span.get_tags_as_map["key1"]
    span.finish
    tracer.close
  end
end
