# frozen_string_literal: true

# Wavefront Tracer.
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

require 'opentracing'
require 'securerandom'
require 'time'
require 'wavefront/client'
require 'wavefront/metrics'
require 'wavefront/client/common/heartbeater'
require_relative 'propagation/registry'
require_relative 'reporting/wavefront'
require_relative 'scope_manager'
require_relative 'span'
require_relative 'span_context'

module WavefrontOpentracing
  # Wavefront Tracer implementation defines the APIs to start Span,
  # to inject SpanContext to and extract SpanContext from a carrier.
  class Tracer
    @@logger = Logger.new(STDERR)
    @@logger.level = Logger::WARN

    # @return [ScopeManager] Provides access to the current ScopeManager.
    attr_reader :scope_manager

    DURATION_SUFFIX = '.duration.micros'
    ERROR_SUFFIX = '.error'
    INVOCATION_SUFFIX = '.invocation'
    TOTAL_TIME_SUFFIX = '.total_time.millis'
    OPERATION_NAME_TAG = 'operationName'

    WAVEFRONT_GENERATED_COMPONENT = 'wavefront-generated'
    OPENTRACING_COMPONENT = 'opentracing'
    RUBY_COMPONENT = 'ruby'

    HEARBEAT_COMPONENTS = [
      WAVEFRONT_GENERATED_COMPONENT,
      OPENTRACING_COMPONENT,
      RUBY_COMPONENT
    ].freeze

    # Construct Wavefront Tracer
    #
    # @param reporter [Reporter] propagation reporter
    # @param application_tags [ApplicationTags] Application tags object
    # @param global_tags [Hash] Global tags for Tracer
    def initialize(reporter, application_tags, global_tags = nil, report_freq_millis = 1000)
      @reporter = reporter
      @tags = global_tags || {}
      @tags.update(application_tags.as_dict)
      @registry = Propagation::Registry.new
      @scope_manager = ScopeManager.new

      @internal_reporter = nil
      @heartbeater = nil
      if !reporter.nil? && reporter.class == Reporting::WavefrontSpanReporter
        begin
          @app_service_prefix = "tracing.derived.#{application_tags.application}.#{application_tags.service}."
          @internal_reporter = Reporters::Wavefront.new(@reporter.sender, application_tags, reporting_interval_sec: report_freq_millis / 1000.0, host: @reporter.source)
          @heartbeater = Wavefront::HeartbeaterService.new(@reporter.sender, application_tags, HEARBEAT_COMPONENTS, @reporter.source)
        rescue StandardError => e
          @@logger.add(Logger::ERROR, "Failed to create internal reporter. Derived metrics will be unavailable. #{e}\n\t#{e.backtrace.join("\n\t")}")
          # Don't raise again as this isn't fatal
        end
      end
    end

    # Start and return a new `Span` representing a unit of work.
    #
    # @param operation_name [String] Operation Name
    # @param child_of [WavefrontSpanContext or WavefrontSpan] (Optional)
    #   A WavefrontSpan or WavefrontSpanContext instance representing
    #   the parent in a REFERENCE_CHILD_OF reference.
    #   If specified, the `references` parameter must be omitted.
    # @param references [List of Opentracing.Reference] (Optional)
    #   references that identify one or more parent `SpanContext`.
    # @param tags [Hash] (Optional) List of tags
    # @param start_time [Time] (Optional) Span start time as Time.now()
    # @param ignore_active_span [Boolean] An explicit flag that ignores
    #   the current active `Scope` and creates a root `Span`.
    # @return [Span] An already started Wavefront Span instance.
    def start_span(operation_name,
                   child_of: nil,
                   references: nil,
                   tags: nil,
                   start_time: nil,
                   ignore_active_span: false)
      parents = []
      follows = []
      baggage = {}
      tags ||= {}
      tags.update(@tags)
      start_time ||= Time.now

      parent = nil
      if !child_of.nil?
        parent = child_of
        parent = child_of.context if parent.is_a?(Span)
        parents << parent.span_id
      elsif parent.nil? && references
        references = [references] unless references.is_a?(Array)
        references.each do |reference|
          next unless reference.is_a?(OpenTracing::Reference)

          reference_ctx = reference.context
          reference_ctx = reference_ctx.context if reference_ctx.is_a?(Span)
          parent = reference_ctx if parent.nil?
          if reference.type == OpenTracing::Reference.CHILD_OF
            parents << reference_ctx.span_id
          elsif reference.type == OpenTracing::Reference.FOLLOWS_FROM
            follows << reference_ctx.span_id
          end
        end
      end

      if parent.nil? || !parent.trace?
        if !ignore_active_span && !active_span.nil?
          parents << active_span.span_id
          trace_id = active_span.trace_id
          span_id = SecureRandom.uuid
        else
          trace_id = SecureRandom.uuid
          span_id = trace_id
        end
        baggage.update(parent.baggage) if parent&.baggage
      else
        trace_id = parent.trace_id
        span_id = SecureRandom.uuid
      end

      span_ctx = SpanContext.new(trace_id, span_id, baggage)
      Span.new(self,
               operation_name,
               span_ctx,
               start_time,
               parents,
               follows,
               tags)
    end

    # Return a newly started and activated `Scope`.
    #
    # @param operation_name [String] Operation Name
    # @param child_of [WavefrontSpanContext or WavefrontSpan] (Optional)
    #   A WavefrontSpan or WavefrontSpanContext instance representing
    #   the parent in a REFERENCE_CHILD_OF reference.
    #   If specified, the `references` parameter must be omitted.
    # @param references [List of Opentracing.Reference] (Optional)
    #   references that identify one or more parent `SpanContext`.
    # @param tags [Hash] (Optional) List of tags
    # @param start_time [Time] (Optional) Span start time as Time.now()
    # @param ignore_active_span [Boolean] An explicit flag that ignores
    #   the current active `Scope` and creates a root `Span`.
    # @param finish_on_close [Boolean] Whether span should be automatically
    #   finished when Scope's close is called.
    # @return [Scope] An newly started and activated Scope instance.
    def start_active_span(operation_name,
                          child_of: nil,
                          references: nil,
                          tags: nil,
                          start_time: nil,
                          ignore_active_span: false,
                          finish_on_close: true)
      scope_manager.activate(
        start_span(operation_name,
                   child_of: child_of,
                   references: references,
                   tags: tags,
                   start_time: start_time,
                   ignore_active_span: ignore_active_span),
        finish_on_close: finish_on_close
      )
    end

    # Inject `SpanContext` into `carrier`.
    # The type of `carrier` is determined by `format`.
    #
    # @param span_context [SpanContext] SpanContext object to inject
    # @param format [Carrier Format] Carrier format
    # @param carrier [Object] the format-specific carrier object to inject
    def inject(span_context, format, carrier)
      propagator = @registry.get(format)
      raise ArgumentError, "Invalid format `#{format}`" unless propagator

      span_context = span_context.context if span_context.is_a?(Span)
      unless span_context.is_a?(SpanContext)
        raise TypeError,
              "Expecting Wavefront SpanContext, not '#{span_context.class}'"
      end

      propagator.inject(span_context, carrier)
    end

    # Extract the `SpanContext` from a `carrier`.
    #
    # @param format [Carrier Format] Carrier format
    # @param carrier [Object] the format-specific carrier object to extract
    # @return [SpanContext] SpanContext extracted from 'carrier' or 'nil'.
    def extract(format, carrier)
      propagator = @registry.get(format)
      raise ArgumentError, "Invalid format #{format}" unless propagator

      propagator.extract(carrier)
    end

    # Close the reporter to close the tracer.
    def close
      @heartbeater&.stop
      @internal_reporter&.stop
      @reporter.close
    end

    # Report span through the reporter.
    #
    # @param span [Span] Wavefront Span instance.
    def report_span(span)
      @reporter.report(span)
    end

    def report_derived_metrics(span)
      return if @internal_reporter.nil?

      point_tags = { OPERATION_NAME_TAG => span.operation_name }

      invc_counter = "#{@app_service_prefix}#{span.operation_name}#{INVOCATION_SUFFIX}"
      @internal_reporter.registry.counter(invc_counter, point_tags).inc

      if span.tags.key?('error')
        err_counter = "#{@app_service_prefix}#{span.operation_name}#{ERROR_SUFFIX}"
        @internal_reporter.registry.counter(err_counter, point_tags).inc
      end

      time_counter = "#{@app_service_prefix}#{span.operation_name}#{TOTAL_TIME_SUFFIX}"
      @internal_reporter.registry.counter(time_counter, point_tags).inc(span.duration_time.to_i)

      dur_histogram = "#{@app_service_prefix}#{span.operation_name}#{DURATION_SUFFIX}"
      @internal_reporter.registry.distribution(dur_histogram, point_tags).push(span.duration_time.to_i * 1000.0) # micros
    end

    # Return the active_span from scope_stack
    #
    # @return [Span, nil] the active span. This is a shorthand for
    #   `scope_manager.active.span`, and nil will be returned if
    #   Scope#active is nil.
    def active_span
      scope = scope_manager.active
      scope&.span
    end
  end
end
