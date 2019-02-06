# Abstract Class of Reporter.
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

module Reporting

  # Wavefront Opentracing
  class Reporter
    # Wavefront Opentracing Reporter
    def initialize(source: nil)
      # Construct reporter.
      # @param source [String]: Source of the reporter

      @source = source
    end

    def report(span)
      # Report tracing span.
      # @param wavefront_span [Span]: Wavefront span to be reported
      raise NotImplementedError
    end

    def failure_count
      # Get failure count of the reporter.
      # @return [int]: Failure count
      raise NotImplementedError
    end

    def close
      # Close the reporter
      raise NotImplementedError
    end
  end
end
