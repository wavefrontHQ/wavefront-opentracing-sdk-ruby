# Wavefront Span Reporter.
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

require 'logger'
require_relative 'reporter'

module Reporting

  # Wavefront Span Reporter
  class WavefrontSpanReporter < Reporter

    logger = Logger.new(STDOUT)
    logger.level = Logger::WARN

    def initialize(client:, source: nil)
      # Construct Wavefront Span Reporter
      # @param client [WavefrontProxyClient or WavefrontDirectClient] :
      # Wavefront Client
      # @param source [String] : Source of the reporter

      @sender = client
      @source = source
#      super(source: source)
    end

    def report(wavefront_span)
      # Report span data via Wavefront Client.
      # @param wavefront_span: Wavefront Span to be reported.

      @sender.send_span(
        wavefront_span.operation_name,
        (wavefront_span.start_time * 1000).to_i,
        (wavefront_span.duration_time * 1000).to_i,
        @source,
        wavefront_span.trace_id,
        wavefront_span.span_id,
        wavefront_span.parents,
        wavefront_span.follows,
        wavefront_span.tags,
        span_logs = nil
      )
      rescue ArgumentError, TypeError => exception
        logger.add(Logger::ERROR) do
          'Invalid Sender, no valid send_span function.'
        end
      raise exception
    end

    def failure_count
      # Get failure count from wavefront client.
      # @return [int]: Failure count

      @sender.failure_count
    end

    def close
      # Close the Wavefront client

      @sender.close
    end
  end
end
