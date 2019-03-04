# Propagator Registry.
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

require 'opentracing'
require_relative 'textmap'
require_relative 'http'

module Propagation
  # Registry of available propagators.
  class Registry

    def initialize
      # Construct propagator registry.

      @propagators = {
        OpenTracing::FORMAT_TEXT_MAP => Propagation::TextMapPropagator.new,
        OpenTracing::FORMAT_RACK => Propagation::HTTPPropagator.new
      }
    end

    def get(format)
      # Get propagator of certain format.
      # @param format [OpenTracing::FORMAT] : Format a propagator
      # @return Propagator of given format

      @propagators[format]
    end

    def register(format, propagator)
      # Register propagator.
      # @param format [OpenTracing::FORMAT] : Format a propagator
      # @param propagator [Propagator] : Propagator to be registered.

      @propagators.merge!(format => propagator)
    end
  end
end
