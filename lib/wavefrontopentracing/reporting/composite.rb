# Composite Reporter
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

require_relative 'reporter'

module Reporting

  # Composite Reporter
  class CompositeReporter < Reporter

    # Used to create multiple reporters, such as create a console
    # reporter and Wavefront direct reporter at the same time.

    def initialize(*reporters)
      # Construct composite reporter
      # @param reporters [Reporter]: Reporters of composite reporter
      super
      @reporters = reporters
    end

    def report(wavefront_span)
      # Each reporter report data.
      # @param wavefront_span: Wavefront span to be reported

      @reporters.each do |rep|
        rep.report(wavefront_span)
      end
    end

    def failure_count
      # Total failure count of all reporters
      # @return [int]: Total failure count
      reporter = 0
      @reporters.each do |rep|
        reporter += rep.failure_count
      end
      reporter
    end

    def close
      # Close all reporters inside the composite reporter.
      @reporters.each &:close
    end
  end
end
