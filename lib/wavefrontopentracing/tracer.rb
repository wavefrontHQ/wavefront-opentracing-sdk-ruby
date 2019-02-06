# Wavefront Tracer.
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

require 'opentracing'
require 'time'
require 'securerandom'
require_relative 'span'
require_relative 'span_context'
require_relative 'scope_manager'
require_relative 'reporting/wavefront'
require_relative 'propagation/registry'

module WavefrontOpentracing
  # Wavefront Tracer
  class Tracer < OpenTracing::Tracer

    def initialize(reporter, application_tags = nil, global_tags = nil)
      # Construct Wavefront Tracer

      # @param reporter [Reporter] : propagation reporter
      # @param application_tags [Hash] : Application tags
      # @param tags [Hash] : Global tags for Tracer
      @reporter = reporter
      @tags = Concurrent::Hash.new
      unless global_tags.nil?
        @tags.update(global_tags.each { |k, v| @tags[k] = v.to_s })
      end
      unless application_tags.nil?
        @tags.update(application_tags.each { |k, v| @tags[k] = v.to_s })
      end
      @registry = Propagation::Registry.new
      @scope_manager = ScopeManager.new
    end

    attr_reader :scope_manager

    # @return [Span, nil] the active span. This is a shorthand for
    #   `scope_manager.active.span`, and nil will be returned if
    #   Scope#active is nil.
    def active_span
      scope = scope_manager.active
      scope.span if scope
    end


    def start_span(operation_name,
                   child_of = nil,
                   references = nil,
                   tags = nil,
                   start_time = nil,
                   ignore_active_span = false)
      # Start and return a new :class:`Span` representing a unit of work.

      # @param operation_name [String] : Operation Name
      # @param child_of [WavefrontSpanContext or WavefrontSpan] (Optional) :
      #   A WavefrontSpan or WavefrontSpanContext instance representing
      #   the parent in a REFERENCE_CHILD_OF reference.
      #   If specified, the `references` parameter must be omitted.
      # @param references [List of Opentracing.Reference] (Optional) :
      #   references that identify one or more parent :class:`SpanContext`.
      # @param tags [Hash] (Optional) : List of tags
      # @param start_time [Float] (Optional) : Span start time as a unix timestamp
      # @param ignore_active_span [Boolean] : An explicit flag that ignores
      # the current active `Scope` and creates a root `Span`.

      # @return [Span] : An already started Wavefront Span instance.

      parents = []
      follows = []
      baggage = nil
      tags ||= Concurrent::Hash.new
      tags.update(tags.each { |k, v| @tags[k] = v.to_s }) unless tags.nil?
      start_time ||= Time.now

      parent = nil
      if !child_of.nil?
        parent = child_of
        # allow both Span and SpanContext to be passed as child_of
        parent = child_of.context if parent.is_a?(WavefrontOpentracing::Span)
        parents << parent.get_span_id

      elsif parent.nil? && references
        references = [references] unless references.is_a?(Array)
        references.each do |reference|
          next unless reference.is_a?(OpenTracing::Reference)

          reference_ctx = reference.context
          # allow both Span and SpanContext to be passed as reference
          reference_ctx = reference_ctx.context if
              reference_ctx.is_a?(WavefrontOpentracing::Span)

          parent = reference_ctx if parent.nil?

          if reference.type == OpenTracing::Reference.CHILD_OF
            parents << reference_ctx.span_id
          elsif reference.type == OpenTracing::Reference.FOLLOWS_FROM
            follows << reference_ctx.span_id
          end
        end
      end

      if parent.nil? || !parent.trace?
        if !ignore_active_span && !@active_span.nil?
          parents << @active_span.span_id
          trace_id = @active_span.trace_id
          span_id = SecureRandom.uuid
        else
          trace_id = SecureRandom.uuid
          span_id = trace_id
        end
        baggage = {}
        baggage.update(parent.baggage) if parent && parent.baggage
      else
        trace_id = parent.trace_id
        span_id = SecureRandom.uuid
      end

      span_ctx = WavefrontOpentracing::SpanContext.new(trace_id, span_id, baggage)
      WavefrontOpentracing::Span.new(self, operation_name, span_ctx, start_time, parents, follows, tags)
    end

    def start_active_span(operation_name,
                          child_of = nil,
                          references = nil,
                          tags = nil,
                          start_time = nil,
                          ignore_active_span = false,
                          finish_on_close = true)
      span = start_span(operation_name, child_of, references, tags, start_time,
                       ignore_active_span),
      scope = @scope_manager.activate(span, finish_on_close: finish_on_close)

      if block_given?
        begin
          yield scope
        ensure
          scope.close
        end
      else
        scope
      end
    end

    def inject(span_context, format, carrier)
      # Inject `span_context` into `carrier`.
      # The type of `carrier` is determined by `format`.
      # @param span_context [SpanContext] : SpanContext object to inject
      # @param format [Carrier Format] : Carrier format
      # @param carrier [Object] : the format-specific carrier object to inject

      propagator = @registry.get(format)
      raise StandardError, 'Invalid format ' + format.to_s unless propagator

      span_context = span_context.context if span_context.is_a?(WavefrontOpentracing::Span)
      unless span_context.is_a?(WavefrontOpentracing::SpanContext)
        raise TypeError, 'Expecting Wavefront SpanContext, not ' + span_context.class.to_s
      end

      propagator.inject(span_context, carrier)
    end

    def extract(format, carrier)
      # Return a :class:`SpanContext` instance extracted from a `carrier`.
      # @param format [Carrier Format] : Carrier format
      # @param carrier [Object] : the format-specific carrier object to extract
      # @return [SpanContext] : SpanContext extracted from 'carrier' or 'nil'.

      propagator = @registry.get(format)
      raise StandardError, 'Invalid format ' + format.to_s unless propagator

      propagator.extract(carrier)
    end

    def close
      # Close the reporter to close the tracer.
      @reporter.close
    end

    def report_span(span)
      # Report span through the reporter.
      # @param span [Span] : Wavefront Span instance.
      @reporter.report(span)
    end
  end
end