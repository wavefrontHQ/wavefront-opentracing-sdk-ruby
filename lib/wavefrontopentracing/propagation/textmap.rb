# frozen_string_literal: true

# TextMap Propagator.
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

require 'securerandom'
require_relative 'propagator'
require_relative '../span_context'

module Propagation
  class TextMapPropagator < Propagator
    include WavefrontOpentracing
    # Propagate contexts within TextMaps
    BAGGAGE_PREFIX = "wf_ot_".freeze
    TRACE_ID = BAGGAGE_PREFIX + "traceid".freeze
    SPAN_ID = BAGGAGE_PREFIX + "spanid".freeze

    # Inject the given `SpanContext` into TextMap Carrier.
    #
    # @param span_context [SpanContext] Wavefront Span Context to be injected
    # @param carrier [Hash] Carrier
    def inject(span_context, carrier)
      carrier[TRACE_ID] = span_context.trace_id
      carrier[SPAN_ID] = span_context.span_id

      if span_context.baggage
        span_context.baggage.each do |key, val|
          carrier.merge!(BAGGAGE_PREFIX + key => val)
        end
      end
    end

    # Extract wavefront span context from the given carrier.
    #
    # @param carrier [Hash] Carrier
    # @return [SpanContext] Wavefront Span Context
    def extract(carrier)
      trace_id = nil
      span_id = nil
      baggage = {}

      unless carrier.is_a?(Hash)
        raise TypeError, 'Carrier not a text map collection.'
      end

      carrier.each do |key, val|
        key = key.downcase
        if key.include? TRACE_ID
          trace_id = val # TODO: if validate_uuid(val)
        elsif key.include? SPAN_ID
          span_id = val # TODO: if validate_uuid(val)
        elsif key.include? BAGGAGE_PREFIX
          baggage.merge!(
            key[key.index(BAGGAGE_PREFIX) + BAGGAGE_PREFIX.length..-1] => val
          )
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
