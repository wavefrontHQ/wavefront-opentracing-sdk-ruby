# Wavefront Span.
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

require 'concurrent'
require 'time'
require 'opentracing'
require_relative 'span_context'
require_relative 'tracer'

module WavefrontOpentracing
  # Wavefront Span
  class Span < OpenTracing::Span

    def initialize(tracer, operation_name, context, start_time = Time.now,
                   parents = nil, follows = nil, tags = nil)
      # Construct Wavefront Span.
      # @param tracer [Tracer]: Tracer that create this span
      # @param operation_name [String]: Operation Name
      # @param context [WavefrontSpanContext]: Span Context
      # @param start_time [time.time()]: an explicit Span start time as a unix
      #                                  timestamp per
      # @param parents [uuid.UUID]: List of UUIDs of parents span
      # @param follows [uuid.UUID]: List of UUIDs of follows span
      # @param tags [Hash]: initial key:value tags (per set_tag) of the Span
#      super(tracer, context)
      @tracer = tracer
      @context = context
      @operation_name = operation_name
      @start_time = start_time.to_f
      @parents = parents
      @duration_time = 0.0
      @follows = follows
      @tags = Concurrent::Hash.new
      @tags.update(tags.each { |k, v| tags[k] = v.to_s }) unless tags.nil?
      @finished = false
    end

    def context
      # Get WavefrontSpanContext of WavefrontSpan.
      # @return [SpanContext] : Span context of current span.
      @context
    end

    def set_tag(key, value)
      # Set tag of the span.
      # @param key [String] the key of the tag
      # @param value [String] the value of the tag. If it's not a String
      # it will be encoded with to_s
      unless key.nil?
        tags[key] = value.to_s unless value.nil?
        self
      end
    end

    def set_baggage_item(key, value)
      # Replace span context with the updated dict of baggage.
      # @param key [String]: key of the baggage item
      # @param value [String]: value of the baggage item
      # @return [WavefrontSpan]: span itself
      @context = SpanContext.new(@context.span_id, @context.trace_id,
                                 @context.baggage.merge!(key => value))
      self
    end

    def get_baggage_item(key)
      # Get baggage item with given key.
      # @param key [String]: Key of baggage item
      # @return [String]: Baggage item value
      @context.baggage[key]
    end

    def finish(end_time= nil)
      # Call finish to finish current span, and report it.
      # @param end_time [Float]: finish time, unix timestamp.
      if !end_time.nil?
        do_finish(end_time.to_f - @start_time)
      else
        time = Time.now.to_f
        do_finish(time - @start_time)
      end
    end

    def do_finish(duration_time)
      # Mark span as finished and send it via reporter.
      # @param duration_time [Float]: Duration time in seconds
      # Thread.lock to be implemented
      if @finished
        @duration_time = duration_time
        @finished = true
      end
      @tracer.report_span(self)
    end

    def trace_id
      # Get trace id.
      # @return [uuid.UUID]: WavefrontTrace id
      @context.get_trace_id
    end

    def duration_time
      # Get span duration time.
      # @return [Float]: Span duration time in seconds.
      @duration_time
    end

    def follows
      # Get list of follows span's id.
      # @return [uuid.UUID]: list of follows span's id
      return [] unless @follows

      @follows
    end

    def tags_as_list
      # Get tags in list format.
      # @return: list of tags
      @tags
    end

    def tags_as_map
      # Get tags in map format.
      # @return: tags in map format: {key: [list_of_val]}
      return {} unless tags

      tag_map = {}
      tag_map.update(tags.each { |k, v| tags[k] = v.to_s })
      tag_map unless tags.nil?
    end

    def span_id
      @context.get_span_id
    end
  end
end
