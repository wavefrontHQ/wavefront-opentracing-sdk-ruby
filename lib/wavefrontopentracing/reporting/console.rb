# Wavefront Console Reporter.
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

require 'wavefront/client'
require_relative 'reporter'

module Reporting
  # Console Reporter to print span data to console.
  class ConsoleReporter < Reporter

    # Print span data to console
    #
    # @param wavefront_span [Span] Wavefront span to be reported.
    def report(wavefront_span)
      line_data = Wavefront::WavefrontUtil.tracing_span_to_line_data(
        wavefront_span.operation_name,
        (wavefront_span.start_time * 1000).to_i,
        (wavefront_span.duration_time * 1000).to_i,
        @source,
        wavefront_span.trace_id,
        wavefront_span.span_id,
        wavefront_span.parents,
        wavefront_span.follows,
        wavefront_span.tags,
        nil,
        'unknown'
      )
    end

    def failure_count
      0
    end

    def close; end
  end
end
