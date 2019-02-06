# Abstract class of Propagator
#
# @author: Gangadharaswamy (gangadhar@vmware.com)


module Propagation

  class Propagator

    def inject(_span_context, _carrier)
      # Inject the given context into the given carrier.
      # @param span_context [SpanContext]: The span context to serialize
      # @param carrier [object]: The carrier to inject the span context into

      raise NotImplementedError
    end

    def extract(_carrier)
      # Extract Wavefront span context from the given carrier.
      # @param carrier [object]: The carrier to extract the span context from
      # @return [WavefrontSpanContext]: Extracted Wavefront Span Context

      raise NotImplementedError
    end
  end
end
