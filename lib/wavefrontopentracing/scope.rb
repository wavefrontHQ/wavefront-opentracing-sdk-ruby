# Wavefront Opentracing Scope.
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

module WavefrontOpentracing
  class Scope

    # Return the Span scoped by this Scope
    #
    # @return [Span]
    attr_reader :span

    # Construct the Wavefront `Scope`.
    #
    # @param span [WavefrontSpan] Wavefront Span.
    # @param scope_stack [ScopeStack] Thread identifier
    # @param finish_on_close [Boolean] Close the scope if true.
    def initialize(span, scope_stack, finish_on_close:)
      @span = span
      @scope_stack = scope_stack
      @finish_on_close = finish_on_close
      @closed = false
    end

    # Close scope
    #
    # Mark the end of the active period for the current thread and Scope,
    # updating the ScopeManager#active in the process.
    def close
      raise "Tried to close already closed span: #{inspect}" if @closed
      @closed = true

      @span.finish if @finish_on_close
      removed_scope = @scope_stack.pop

      if removed_scope != self
        raise 'Removed non-active scope, ' \
          "removed: #{removed_scope.inspect}, "\
          "expected: #{inspect}"
      end
    end
  end
end
