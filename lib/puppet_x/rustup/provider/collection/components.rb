# frozen_string_literal: true

require_relative 'subresources'

# A component subresource collection
class PuppetX::Rustup::Provider::Collection::Components <
    PuppetX::Rustup::Provider::Collection::Subresources
  # Get components installed on the system.
  def load
    @system = @provider.toolchains.system.reduce([]) do |combined, info|
      toolchain_name = info['toolchain']
      combined + list_installed(toolchain_name).map do |component_name|
        {
          'ensure' => 'present',
          'name' => component_name,
          'toolchain' => toolchain_name,
        }
      end
    end
  end

  # Normalize component.
  def normalize(component)
    # FIXME
    component
  end

  # Get list of installed components for a toolchain
  def list_installed(toolchain)
    @provider
      .rustup('component', 'list', '--installed', '--toolchain', toolchain)
      .lines(chomp: true)
      .reject { |line| line.start_with? 'error: ' }
  end

  # Install a component
  def install(subresource)
    if subresource['toolchain'].nil?
      raise Puppet::Error, 'Toolchain must be specified to install component'
    end
    @provider.rustup 'component', 'add', '--toolchain',
      subresource['toolchain'], subresource['name']
  end

  # Uninstall a component
  def uninstall(subresource)
    if subresource['toolchain'].nil?
      raise Puppet::Error, 'Toolchain must be specified to install component'
    end
    @provider.rustup 'component', 'remove', '--toolchain',
      subresource['toolchain'], subresource['name']
  end
end
