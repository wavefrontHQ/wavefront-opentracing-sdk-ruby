# Composite Reporter to report same span data to multiple reporters
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

require_relative 'reporter'

module Reporting
  # Composite Reporter can send same span data to multiple reporters
  # at the same time, such as
  # `WavefrontSpanReporter` - for `via_proxy` ingestion of data
  # `WavefrontSpanReporter` - for `direct_ingestion` of data
  # `ConsoleReporter` - to print data on console
  class CompositeReporter < Reporter

    # Construct the `CompositeReporter`
    #
    # @param reporters [<Reporter>] Reporters of composite reporter.
    def initialize(*reporters)
      @reporters = reporters
    end

    # Each reporter report data.
    # @param wavefront_span [Span] Wavefront span to be reported.
    def report(wavefront_span)
      @reporters.each do |rep|
        rep.report(wavefront_span)
      end
    end

    # Total failure count of all reporters
    # @return [Integer] Total failure count
    def failure_count
      total_count = 0
      @reporters.each do |rep|
        total_count += rep.failure_count
      end
      total_count
    end

    # Close all reporters inside the composite reporter.
    def close
      @reporters.each &:close
    end
  end
end
