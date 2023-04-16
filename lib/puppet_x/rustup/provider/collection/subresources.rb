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

  # Install and uninstall subresources as appropriate.
  #
  # Note that this does not update the internal state after changing the system.
  # You must call `load` after this if you need the state to be correct.
  #
  # This takes `resource[:<whatever>]` as a parameter instead of using the set
  # value of this collection because the value isn’t set if it is initially
  # unchanged. That means if the values on the system change after `load` was
  # called but before this method was called, we won’t be able to tell.
  def manage(requested, purge)
    system_grouped = system.group_by { |info| info['toolchain'] }
    group_subresources_by_toolchain(requested) do |toolchain, subresources|
      unmanaged = manage_group(system_grouped[toolchain] || [], subresources)

      if purge
        uninstall_all(unmanaged)
      end
    end
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
      yield toolchain.name, by_toolchain.delete(toolchain.name) || []
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

  # Install or uninstall a group of subresources by comparing them to what’s
  # already present on the system.
  #
  # Returns subresourecs found on the system, but not declared in the resource.
  def manage_group(on_system, requested)
    requested.each do |subresource|
      subresource['normalized_name'] = normalize(subresource['name'])

      # Remove installed subresource from the on_system list.
      found = on_system.reject! do |info|
        info['name'] == subresource['normalized_name']
      end

      if subresource['ensure'] == 'absent'
        if found
          uninstall(subresource)
        end
      elsif found.nil? || subresource['ensure'] == 'latest'
        # ensure == 'present' implied
        install(subresource)
      end
    end

    # Return unmanaged subresources.
    on_system
  end

  # Uninstall all subresourcecs in an array.
  def uninstall_all(subresources)
    subresources.each do |subresource|
      uninstall(subresource)
    end
  end
end
