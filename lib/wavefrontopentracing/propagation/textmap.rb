# TextMap Propagator.
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

require 'securerandom'
require_relative 'propagator'
require_relative '../span_context'

module Propagation

  # TextMap Propagator
  class TextMapPropagator < Propagator
    include WavefrontOpentracing
    # Propagate contexts within TextMaps
    BAGGAGE_PREFIX = "wf-ot-".freeze
    TRACE_ID = BAGGAGE_PREFIX + "traceid".freeze
    SPAN_ID = BAGGAGE_PREFIX + "spanid".freeze

    def inject(span_context, carrier)
      # Inject the given Span Context into TextMap Carrier.
      # @param span_context [SpanContext]: Wavefront Span Context to be injected
      # @param carrier [dict]: Carrier

      # TO_DO: Check, carrier is not of Hash type always
#      unless carrier.is_a?(Hash)
#        raise TypeError, 'Carrier not a text map collection.'
#      end

      carrier[TRACE_ID] = span_context.trace_id
      carrier[SPAN_ID] = span_context.span_id

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
        raise TypeError, 'Carrier not a text map collection.'
      end

      carrier.each do |key, val|
        key = key.downcase

        if key == TRACE_ID
          trace_id = val # To-Do: if validate_uuid(val)
        elsif key == SPAN_ID
          span_id = val # To-Do: if validate_uuid(val)
        elsif key.start_with?(BAGGAGE_PREFIX)
          baggage.merge!(key[BAGGAGE_PREFIX.length..-1] => val)
        end
      end

      if trace_id.nil? || span_id.nil?
        nil
      else
        SpanContext.new(trace_id, span_id, baggage)
      end
    end

#    private
#
#    def validate_uuid(uuid)
#      uuid_regex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
#      uuid_regex.match?(uuid.to_s) ? true : false
#
#      raise ArgumentError, "Invalid UUID string: '#{uuid}'"
#    end
  end
end
