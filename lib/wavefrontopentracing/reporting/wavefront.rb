# frozen_string_literal: true

# Wavefront Span Reporter.
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

require 'concurrent'
require 'logger'
require 'wavefront/client'
require 'wavefront/client/internal-metrics/registry'

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

      # internal metrics
      @internal_store = ::Wavefront::InternalMetricsRegistry.new(::Wavefront::SDK_METRIC_PREFIX + '.opentracing.reporter', @application_tags)

      @internal_store.gauge('queue.size') { @queue.size }
      @internal_store.gauge('queue.remaining_capacity') { @queue.max - @queue.size }

      @spans_received = @internal_store.counter('spans.received')
      @spans_dropped = @internal_store.counter('spans.dropped')
      @errors = @internal_store.counter('errors')

      @internal_reporter = ::Wavefront::InternalReporter.new(@sender, @internal_store)
    end

    # Report span data via Wavefront Client.
    #
    # @param wavefront_span [Span] Wavefront Span to be reported.
    def report(wavefront_span)
      @spans_received.inc # should count even if dropped
      @queue.push(wavefront_span, non_block = true)
    rescue ThreadError => e
      @@logger.warn "Reporter - Queue exceeded max capacity(#{@queue.max}). Dropping spans..."
      @spans_dropped.inc
    rescue StandardError => e
      @@logger.error "Unexpected Error: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
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
          @errors.inc
          @@logger.error "SpanReporter - Error sending span : #{e.message}\n\t" + e.backtrace.join("\n\t")
        end
      end
    ensure
      @exec.post { report_task } unless @closed.true?
    end
  end
end
