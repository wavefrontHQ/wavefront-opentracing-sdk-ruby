# Wavefront Span.
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

require 'concurrent'
require 'time'
require 'wavefront/client/common/utils'
require_relative 'span_context'

module WavefrontOpentracing
  class Span

    # @return [SpanContext] provides wavefront span context
    attr_reader :context
    # @return [String] provides span operation name
    attr_reader :operation_name
    # @return [Time] provides span start time object
    attr_reader :start_time
    # @return [<UUID>] provides a list of UUID's of parents span
    attr_reader :parents
    # @return [Integer] provides span duration
    attr_reader :duration_time
    # @return [<UUID>] provides a list of UUID's of follows span
    attr_reader :follows
    # @return [Hash] provides a list of tags of span
    attr_reader :tags

    # Construct the Wavefront Span.
    #
    # @param tracer [Tracer] Tracer that create this span
    # @param operation_name [String] Operation Name
    # @param context [WavefrontSpanContext] Span Context
    # @param start_time [Time] an explicit Span start time as Time.now()
    # @param parents [UUID] List of UUIDs of parents span
    # @param follows [UUID] List of UUIDs of follows span
    # @param tags [Hash] List of tags
    def initialize(tracer,
                   operation_name,
                   context,
                   start_time,
                   parents,
                   follows,
                   tags)
      @tracer = tracer
      @context = context
      @operation_name = operation_name
      @start_time = start_time
      @duration_time = 0
      @parents = parents
      @follows = follows
      @tags = tags
      @finished = false
      @update_lock = Mutex.new
    end

    # Set tag of the span.
    #
    # @param key [String] the key of the tag
    # @param value [String] the value of the tag. If it's not a String
    #   it will be encoded with to_s
    def set_tag(key, value)
      @update_lock.synchronize do
        unless Wavefront::WavefrontUtil.is_blank(key) && value.nil?
          @tags.update(key => value.to_s)
        end
      end
    end

    # Get baggage item for the given key.
    #
    # @param key [String] Key of baggage item
    # @return [String] Baggage item value
    def get_baggage_item(key)
      @context.get_baggage_item(key)
    end

    # Replace span context with the updated dict of baggage.
    #
    # @param key [String] key of the baggage item
    # @param value [String] value of the baggage item
    def set_baggage_item(key, value)
      context_with_baggage = @context.with_baggage_item(key, value)
      @update_lock.synchronize do
        @context = context_with_baggage 
      end
    end

    # Update operation name.
    #
    # @param operation_name [String] Operation name.
    def set_operation_name(operation_name)
      @update_lock.synchronize do
        @operation_name = operation_name
      end
    end

    # Call finish to finish current span, and report it.
    #
    # @param end_time [Time] finish time as Time.now().
    def finish(end_time = nil)
      if !end_time.nil?
        do_finish(((end_time - @start_time).to_f * 1000.0).to_i)
      else
        do_finish(((Time.now - @start_time).to_f * 1000.0).to_i)
      end
    end

    # Mark span as finished and send it via reporter.
    #
    # @param duration_time [Integer] Duration time in milliseconds
    # Thread.lock to be implemented
    def do_finish(duration_time)
      @update_lock.synchronize do
        return if @finished

        @duration_time = duration_time
        @finished = true
      end
      @tracer.report_span(self)
    end

    # Get trace id.
    #
    # @return [UUID] Wavefront Trace ID
    def trace_id
      @context.trace_id
    end

    # Get span id.
    #
    # @return [UUID] Wavefront Span ID
    def span_id
      @context.span_id
    end

    # Get tags in list format.
    #
    # @return [List of pair] list of tags
    def get_tags_as_list
      return [] unless @tags

      tags_list = []
      @tags.each do |key, val|
        tags_list.push([key, val])
      end
      tags_list
    end

    # Get tags in map format.
    #
    # @return [Hash] tags in map format
    def get_tags_as_map
      @tags
    end

    def log_kv(timestamp: Time.now, **args)
      args = {} if args.nil?
      record = {
        timestamp: (timestamp.to_f * 1000.0).to_i,
        fields: args.to_a.map do |key, value|
          { key.to_s => value.to_s }
        end
      }
      puts "Span: Logs: #{record}"
    end
  end
end
