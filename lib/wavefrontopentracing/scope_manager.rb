# Wavefront Opentracing Scope Manager
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

require_relative 'scope'

module WavefrontOpentracing
  # ScopeManager represents an OpenTracing ScopeManager
  #
  # The ScopeManager interface abstracts both the activation of Span instances
  # via ScopeManager#activate and access to an active Span/Scope via
  # ScopeManager#active
  #
  class ScopeManager
    def initialize
      @scope_stack = ScopeStack.new
    end

    def activate(span, finish_on_close: true)
      # Make a span instance active
      #
      # @param span [Span] : the Span that should become active
      # @param finish_on_close [Boolean] : whether the Span should automatically be
      #   finished when Scope#close is called
      # @return [Scope] : instance to control the end of the active period for the
      #  Span. It is a programming error to neglect to call Scope#close on the
      #  returned instance.

      return active if active && active.span == span
      scope = Scope.new(span, @scope_stack, finish_on_close: finish_on_close)
      @scope_stack.push(scope)
      scope
    end

    def active
      # Return active scope
      #
      # If there is a non-null Scope, its wrapped Span becomes an implicit parent
      # (as Reference#CHILD_OF) of any newly-created Span at
      # Tracer#start_active_span or Tracer#start_span time.
      #
      # @return [Scope] the currently active Scope which can be used to access the
      #   currently active Span.

      @scope_stack.peek
    end
  end

  class ScopeStack
    def initialize
      # Generate a random identifier to use as the Thread.current key. This is
      # needed so that it would be possible to create multiple tracers in one
      # thread (mostly useful for testing purposes)

      @scope_identifier = ScopeIdentifier.generate
      store
    end

    def push(scope)
      store << scope
    end

    def pop
      store.pop
    end

    def peek
      store.last
    end

    private

    def store
      Thread.current[@scope_identifier] ||= []
    end
  end

  class ScopeIdentifier
    def self.generate
      # 65..90.chr are characters between A and Z
      "wavefrontopentracing_#{(0...8).map { rand(65..90).chr }.join}".to_sym
    end
  end
end
