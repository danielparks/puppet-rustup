# frozen_string_literal: true

require_relative '../provider'

# A collection value in a provider
class PuppetX::Rustup::Provider::Collection
  include Enumerable

  attr_writer :values

  # Use this to set the plural name for the class
  def self.plural_name(plural_name = nil)
    @plural_name ||= plural_name || name.split('::').last
  end

  def initialize(provider)
    @provider = provider
    @system = :unset
    @values = nil
  end

  # Get values actually present on the system.
  def load
    raise 'Unimplemented.'
  end

  # Get the plural_name from the class
  def plural_name
    self.class.plural_name
  end

  # Implement Enumerable
  def each
    if block_given?
      values.each { |value| yield value }
      self
    else
      enum_for(__callee__)
    end
  end

  # Either the subresources set from the resource, or if nothing is set, the
  # subresources on the system.
  def values
    @values || system
  end

  # Get subresources installed on the system (memoized).
  #
  # Just memoizes load.
  def system
    if @system == :unset
      load
    end
    @system
  end
end
