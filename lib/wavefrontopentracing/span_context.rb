# Wavefront Span Context.
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

require_relative 'span'

module WavefrontOpentracing
  # Wavefront Span Context.
  class SpanContext

    attr_reader :baggage

    def initialize(span_id, trace_id, baggage = nil)

      # Construct Wavefront Span Context.
      # @param trace_id [uuid.UUID]: Trace ID
      # @param span_id [uuid.UUID]: Span ID
      # @param baggage [dict]: Baggage
      @span_id = span_id.freeze
      @trace_id = trace_id.freeze
      @baggage = baggage || {}
    end

    def get_baggage_item(key)

      # Get baggage item with key.
      # @param key: Baggage key
      # @[String]: Baggage value
      @baggage[key]
    end

    def with_baggage_item(key, value)

      # Create new span context with new dict of baggage and append item.
      # @param key [String]: key of the baggage item
      # @param value [String]: value of the baggage item
      # @[SpanContext]: Span context itself
      baggage = {}.merge!(@baggage).merge!(key => value)
      SpanContext.new(@span_id, @trace_id, baggage)
    end

    def get_span_id

      # Get span id from span context.
      # @return span_id [UUID] : span id of SpanContext
      @span_id
    end

    def get_trace_id

      # Get trace id from span context.
      # @return trace_id [UUID] : trace id of SpanContext
      @trace_id
    end

    def trace?

      # @[bool]: whether span context has both trace id and span id.
      @trace_id && @span_id ? true : false
    end

    def to_s

      # Override to_s method.
      # @[SpanContext]: span context to string
      "WavefrontSpanContext{traceId=#{@trace_id}, spanId=#{@span_id}}"
    end

    def to_str

      # Override to_str method.
      # @[SpanContext]: span context to string
      to_s
    end
  end
end
