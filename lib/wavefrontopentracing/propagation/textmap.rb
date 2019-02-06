# TextMap Propagator.
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

require_relative 'propagator'
require_relative '../span_context'

module Propagation

  # TextMap Propagator
  class TextMapPropagator < Propagator
    # Propagate contexts within TextMaps
    BAGGAGE_PREFIX = 'wf-ot-'.freeze
    TRACE_ID = BAGGAGE_PREFIX + 'traceid'.freeze
    SPAN_ID = BAGGAGE_PREFIX + 'spanid'.freeze

    def inject(span_context, carrier)
      # Inject the given Span Context into TextMap Carrier.
      # @param span_context [SpanContext]: Wavefront Span Context to be injected
      # @param carrier [Hash]: Carrier

#      unless carrier.is_a?(Hash)
#        raise TypeError.new('Carrier not a text map collection.')
#      end

      carrier[TRACE_ID] = span_context.get_trace_id
      carrier[SPAN_ID] = span_context.get_span_id

      if span_context.baggage
        span_context.baggage.each do |key, val|
          carrier.merge!(BAGGAGE_PREFIX + key => val)
        end
      end
    end

    def extract(carrier)
      # Extract wavefront span context from the given carrier.
      # @param carrier [dict]: Carrier
      # @return [SpanContext]: Wavefront Span Context

      trace_id = nil
      span_id = nil
      baggage = {}
      unless carrier.is_a?(Hash)
        raise TypeError.new(TypeError, 'Carrier not a text map collection.')
      end

      carrier.items.each do |key, val|
        key = key.downcase

        if key == TRACE_ID
          trace_id = UUID(val)
        elsif key == SPAN_ID
          span_id = UUID(val)
        elsif key.start_with?(BAGGAGE_PREFIX)
          baggage.merge!(start_with?(key) ? self[key.length..-1] : self => val)
        end
      end

      if trace_id.nil? || span_id.nil?
        nil
      else
        SpanContext(trace_id, span_id, baggage)
      end
    end
  end
end
