# Wavefront Span Context.
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

module WavefrontOpentracing
  # Wavefront Span Context.
  class SpanContext < OpenTracing::SpanContext

    attr_reader :trace_id, :span_id, :baggage

    def initialize(trace_id, span_id, baggage = nil)
      # Construct Wavefront Span Context.
      # @param trace_id [uuid.UUID]: Trace ID
      # @param span_id [uuid.UUID]: Span ID
      # @param baggage [dict]: Baggage

      @trace_id = trace_id
      @span_id = span_id
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
      SpanContext.new(@trace_id, @span_id, baggage)
    end

    def trace?
      # @return [Boolean]: true if SpanContext has both trace id and span id,
      #                    else false.

      @trace_id && @span_id
    end

    def to_s
      # Override to_s method.
      # @return [String]: SpanContext as string

      "WavefrontSpanContext{traceId=#{@trace_id}, spanId=#{@span_id}}"
    end

    def to_str
      # Override to_str method.
      # @return [String]: SpanContext as string

      to_s
    end
  end
end
