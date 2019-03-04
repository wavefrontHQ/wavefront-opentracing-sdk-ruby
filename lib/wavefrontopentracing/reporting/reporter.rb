# Wavefront Opentracing Reporter
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

module Reporting
  # @abstract Abstract Class of Reporter.
  class Reporter

    # Construct reporter.
    #
    # @param source [String] Source of the reporter.
    def initialize(source: nil)
      @source = source
    end

    # Report tracing span.
    #
    # @param span [Span] Wavefront span to be reported
    def report(span); raise NotImplementedError end

    # Get failure count of the reporter.
    def failure_count; raise NotImplementedError end

    # Close the reporter
    def close; raise NotImplementedError end
  end
end
