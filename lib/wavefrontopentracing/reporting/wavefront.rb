# frozen_string_literal: true

# Wavefront Span Reporter.
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

require 'logger'
require 'wavefront/client'
require 'concurrent'

require_relative 'reporter'

module Reporting
  # Wavefront Span Reporter to report span data either via_proxy or
  # direct_ingestion through wavefront client instance to Wavefront server.
  class WavefrontSpanReporter < Reporter
    @@logger = Logger.new(STDERR) # class instance var
    @@logger.level = Logger::WARN

    # @return [String] Source of the reporter.
    attr_reader :source

    # @return [WavefrontProxyClient or WavefrontDirectClient] Wavefront Client
    attr_reader :sender

    # Construct Wavefront Span Reporter
    #
    # @param client [WavefrontProxyClient or WavefrontDirectClient]
    #   Wavefront Client
    # @param source [String] Source of the reporter.
    def initialize(client:, source: nil, max_queue_size: 50_000)
      @sender = client

      unless @sender.respond_to?(:send_span)
        raise ArgumentError, 'Invalid Sender, no valid send_span function.'
      end

      @source = source

      @closed = Concurrent::AtomicBoolean.new
      @queue = SizedQueue.new(max_queue_size)
      @exec = Concurrent::SingleThreadExecutor.new
      @exec.post { report_task }
    end

    # Report span data via Wavefront Client.
    #
    # @param wavefront_span [Span] Wavefront Span to be reported.
    def report(wavefront_span)
      @queue.push(wavefront_span, non_block = true)
    rescue ClosedQueueError, ThreadError => e
      # queue full/closed?
    rescue StandardError => e
      # other errors
    end

    # Get failure count from wavefront client.
    #
    # @return [Integer] Failure count
    def failure_count
      @sender.failure_count
    end

    # Close the Wavefront client
    def close(timeout = 3)
      @queue.close
      @closed.make_true
      @exec.wait_for_termination(timeout)
      unless @exec.shutdown?
        @exec.kill
        @@logger.warn 'Reporter killed as close exceeded timeout'
      end
      @sender.close
    end

    private

    def report_task
      loop do
        begin
          if @closed.true? && @queue.empty?
            @exec.shutdown
            return
          end
          if wavefront_span = @queue.pop # blocks if queue is empty
            @sender.send_span(
              wavefront_span.operation_name,
              (wavefront_span.start_time.to_f * 1000).to_i,
              wavefront_span.duration_time,
              @source,
              wavefront_span.trace_id,
              wavefront_span.span_id,
              wavefront_span.parents,
              wavefront_span.follows,
              wavefront_span.tags,
              nil # span_logs
            )
          end
        rescue StandardError => e
          @@logger.error "#{e.message}\n\t" + e.backtrace.join("\n\t")
        end
      end
    ensure
      @exec.post { report_task } unless @closed.true?
    end
  end
end
