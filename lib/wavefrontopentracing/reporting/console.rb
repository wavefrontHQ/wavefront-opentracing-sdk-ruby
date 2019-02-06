# Console Reporter.
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

require_relative 'reporter'

module Reporting

  # Console Reporter
  class ConsoleReporter < Reporter

    # Used to print span data to console.
    def report(wavefront_span)
      # Print span data to console
      # @param wavefront_span [WavefrontSpan] : Wavefront span to be reported.
      line_data = tracing_span_to_line_data(
        wavefront_span.operation_name,
        int(wavefront_span.start_time * 1000),
        int(wavefront_span.duration_time * 1000),
        source,
        wavefront_span.trace_id,
        wavefront_span.span_id,
        wavefront_span.parents,
        wavefront_span.follows,
        wavefront_span.tags,
        span_logs: nil,
        default_source: 'unknown'
      )
      print(line_data)
    end

    def failure_count; end

    def close; end
  end
end
