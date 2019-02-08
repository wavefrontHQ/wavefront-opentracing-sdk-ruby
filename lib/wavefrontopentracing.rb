# Wavefront Opentracing Ruby SDK.
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

require 'forwardable'
require_relative 'wavefrontopentracing/version'
require_relative 'wavefrontopentracing/span_context'
require_relative 'wavefrontopentracing/span'
require_relative 'wavefrontopentracing/tracer'
require_relative 'wavefrontopentracing/reporting/reporter'
require_relative 'wavefrontopentracing/reporting/console'
require_relative 'wavefrontopentracing/reporting/wavefront'
require_relative 'wavefrontopentracing/reporting/composite'
require_relative 'wavefrontopentracing/propagation/propagator'
require_relative 'wavefrontopentracing/propagation/registry'
require_relative 'wavefrontopentracing/propagation/textmap'
require_relative 'wavefrontopentracing/propagation/http'

module WavefrontOpentracing
  class << self
    extend SingleForwardable
    # extend Forwardable
    # Global tracer to be used when WavefrontOpentracing.start_span, inject or
    # extract is called
    attr_accessor :global_tracer
    # def_delegators :global_tracer, :scope_manager, :start_active_span,
    #               :start_span, :inject, :extract, :active_span
  end
end
