# Console Reporter.
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

require_relative 'reporter'
require_relative '../../../util/utils'

module Reporting

  # Console Reporter
  class ConsoleReporter < Reporter

    # Used to print span data to console.
    def report(wavefront_span)
      # Print span data to console
      # @param wavefront_span [Span] : Wavefront span to be reported.
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
      print(line_data)
    end

    def failure_count
      0
    end

    def close; end
  end
end
