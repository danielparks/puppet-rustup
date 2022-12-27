# frozen_string_literal: true

require_relative '../collection'

# A subresource collection
class PuppetX::Rustup::Provider::Collection::Subresources <
    PuppetX::Rustup::Provider::Collection
  # Is the passed subresource already installed?
  #
  # @param [String] name
  #   Normalized subresource name.
  # @return [Boolean]
  def installed?(name)
    system.any? { |info| info['name'] == name }
  end

  # Split subresource up by toolchain for management
  #
  # This also verifies that none of the subresources were requested for
  # toolchains with ensure => absent.
  #
  # @param [Hash] requested
  #   `resources[:name]`
  # @yield
  #   A block that takes |toolchain, subresources|
  def group_subresources_by_toolchain(requested)
    by_toolchain = requested.group_by do |subresource|
      @provider.normalize_toolchain_or_default(subresource['toolchain'])
    end

    @provider.toolchains.system.each do |toolchain|
      yield toolchain['name'], by_toolchain.delete(toolchain['name']) || []
    end

    # Find subresources that were requested for uninstalled toolchains.
    missing_toolchains = []
    by_toolchain.each do |toolchain_name, subresources|
      if subresources.any? { |subresource| subresource['ensure'] != 'absent' }
        missing_toolchains << toolchain_name
      end
    end

    unless missing_toolchains.empty?
      raise Puppet::Error, "#{plural_name} were requested for toolchains " \
        "that are not installed: #{missing_toolchains.join(', ')}"
    end
  end
end
