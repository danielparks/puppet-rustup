# frozen_string_literal: true

require_relative '../provider'

# A subresource collection
class PuppetX::Rustup::Provider::Subresources
  include Enumerable

  attr_writer :values

  # Get subresources installed on the system.
  def load
    raise 'Unimplemented.'
  end

  # Use this to set the plural name for the class
  def self.plural_name(name = nil)
    @plural_name ||= name
  end

  def initialize(provider)
    @provider = provider
    @system = :unset
    @values = nil
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

  # Either the toolchains set, or the toolchains on the system
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

  # Split subresource up by toolchain for management
  #
  # This also verifies that none of the subresources were requested for
  # toolchains with ensure => absent.
  #
  # @params [Hash] resources[:name]
  # @params [block] a block that takes |toolchain, subresources|
  def group_subresources_by_toolchain(requested)
    by_toolchain = requested.group_by do |info|
      @provider.normalize_toolchain_or_default(info['toolchain'])
    end

    @provider.toolchains.system.each do |info|
      yield info['toolchain'], by_toolchain.delete(info['toolchain']) || []
    end

    # Find subresources that were requested for uninstalled toolchains.
    missing_toolchains = []
    by_toolchain.each do |toolchain, subresources|
      if subresources.any? { |info| info['ensure'] != 'absent' }
        missing_toolchains << toolchain
      end
    end

    unless missing_toolchains.empty?
      raise Puppet::Error, "#{plural_name} were requested for toolchains " \
        "that are not installed: #{missing_toolchains.join(', ')}"
    end
  end
end
