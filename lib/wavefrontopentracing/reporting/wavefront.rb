# Wavefront Span Reporter.
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

require 'logger'
require_relative 'reporter'

module Reporting
  # Wavefront Span Reporter to report span data either via_proxy or
  # direct_ingestion through wavefront client instance to Wavefront server.
  class WavefrontSpanReporter < Reporter

    logger = Logger.new(STDOUT)
    logger.level = Logger::WARN

    # Construct Wavefront Span Reporter
    #
    # @param client [WavefrontProxyClient or WavefrontDirectClient]
    #   Wavefront Client
    # @param source [String] Source of the reporter.
    def initialize(client:, source: nil)
      @sender = client
      @source = source
    end

    # Report span data via Wavefront Client.
    #
    # @param wavefront_span [Span] Wavefront Span to be reported.
    def report(wavefront_span)
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

    # Get failure count from wavefront client.
    #
    # @return [Integer] Failure count
    def failure_count
      @sender.failure_count
    end

    # Close the Wavefront client
    def close
      @sender.close
    end
  end
end
