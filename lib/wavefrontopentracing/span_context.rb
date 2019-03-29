# Wavefront Span Context.
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

module WavefrontOpentracing
  class SpanContext

    # @return [UUID] provides trace ID
    attr_reader :trace_id
    # @return [UUID] provides span ID
    attr_reader :span_id
    # @return [Hash] provides baggage
    attr_reader :baggage

    # Construct the Wavefront `SpanContext`.
    #
    # @param trace_id [UUID] Trace ID
    # @param span_id [UUID] Span ID
    # @param baggage [Hash] Baggage.
    def initialize(trace_id, span_id, baggage = nil)
      @trace_id = trace_id
      @span_id = span_id
      @baggage = baggage || {}
    end

    # Get baggage item for the given key.
    #
    # @param key [String] Baggage key
    # @return [String] Baggage value.
    def get_baggage_item(key)
      @baggage[key]
    end

    # Create a new `SpanContext` with new dict of baggage and append item.
    #
    # @param key [String] key of the baggage item
    # @param value [String] value of the baggage item
    # @return [SpanContext] Span context itself.
    def with_baggage_item(key, value)
      baggage = {}.merge!(@baggage).merge!(key => value)
      SpanContext.new(@trace_id, @span_id, baggage)
    end

    # Check if the `trace` is valid or not
    #
    # @return [Boolean] true if SpanContext has both trace id and span id,
    #   else false.
    def trace?
      @trace_id && @span_id
    end

    # Override the `to_s` method.
    #
    # @return [String] SpanContext as string.
    def to_s
      "WavefrontSpanContext{traceId=#{@trace_id}, spanId=#{@span_id}}"
    end

    # Override the `to_str` method.
    #
    # @return [String] SpanContext as string.
    def to_str
      to_s
    end
  end
end
