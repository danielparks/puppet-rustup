# frozen_string_literal: true

require_relative '../collection'

# A subresource collection
class PuppetX::Rustup::Provider::Collection::Subresources <
    PuppetX::Rustup::Provider::Collection
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
