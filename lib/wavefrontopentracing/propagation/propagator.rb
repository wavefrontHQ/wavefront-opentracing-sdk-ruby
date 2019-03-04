# Abstract class of Propagator
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

module Propagation
  @abstract
  class Propagator

    # Inject the given context into the given carrier.
    #
    # @param span_context [SpanContext] The span context to serialize
    # @param carrier [Carrier] The carrier to inject the span context into
    def inject(span_context, carrier); raise NotImplementedError end

    # Extract Wavefront span context from the given carrier.
    #
    # @param carrier [Carrier] The carrier to extract the span context from
    # @return [WavefrontSpanContext] Extracted Wavefront Span Context
    def extract(carrier); raise NotImplementedError end
  end
end
