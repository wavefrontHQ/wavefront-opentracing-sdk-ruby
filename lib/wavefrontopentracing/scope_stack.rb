# frozen_string_literal: true

# ScopeStack maintains the stack of `Scope`.
#
# @author: Gangadharaswamy (gangadhar@vmware.com)

require_relative 'scope_manager'

module WavefrontOpentracing
  # ScopeStack maintains the stack of `Scope` with push, pop & peek functions
  class ScopeStack
    # @api private Generates unique identifier for `Scope`
    class ScopeIdentifier

      # Get an identifier for the Scope
      #
      # @return [String] an unique string to identify Scope with
      #   fixed prefix of `wavefrontopentracing_` followed by random generated
      #   upper-case characters.
      def self.generate
        "wavefrontopentracing_#{(0...8).map { rand(65..90).chr }.join}".to_sym
      end
    end

    private_constant :ScopeIdentifier

    # ScopeStack generates a random identifier to use as the Thread.current key.
    # This is needed so that it would be possible to create multiple tracers in
    # one thread (mostly useful for testing purposes).
    def initialize
      @scope_identifier = ScopeIdentifier.generate
      store
    end

    # Push the scope into the ScopeStack
    #
    # @param scope [Scope] instance to control the end of the active period
    #   for the Span.
    def push(scope)
      store << scope
    end

    # Pop the scope from the top of ScopeStack
    #
    # @return [Scope] instance to control the end of the active period
    #   for the Span.
    def pop
      store.pop
    end

    # Get the scope on top of ScopeStack
    #
    # @return [Scope] instance to control the end of the active period
    #   for the Span.
    def peek
      store.last
    end

    private

    # Get the current ScopeIdentifier
    #
    # @return [ScopeIdentifier] random identifier of
    #   ScopeStack
    def store
      Thread.current[@scope_identifier] ||= []
    end
  end
end
