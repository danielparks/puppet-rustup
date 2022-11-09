# frozen_string_literal: true

require_relative 'subresources'

# A target subresource collection
class PuppetX::Rustup::Provider::Collection::Targets <
    PuppetX::Rustup::Provider::Collection::Subresources
  # Get targets installed on the system.
  def load
    @system = @provider.toolchains.system.reduce([]) do |combined, toolchain|
      combined + list_installed(toolchain.name).map do |target_name|
        {
          'ensure' => 'present',
          'name' => target_name,
          'toolchain' => toolchain.name,
        }
      end
    end
  end

  # Normalize target name.
  def normalize(target)
    if target == 'default'
      @provider.default_target
    else
      target
    end
  end

  # Get list of installed targets for a toolchain
  def list_installed(toolchain)
    @provider
      .rustup('target', 'list', '--installed', *toolchain_option(toolchain))
      .lines(chomp: true)
      .reject { |line| line.start_with? 'error: ' }
  end

  # Install a target
  def install(subresource)
    @provider.rustup 'target', 'install',
      *toolchain_option(subresource['toolchain']),
      subresource['normalized_name'] || subresource['name']
  end

  # Uninstall a target
  def uninstall(subresource)
    @provider.rustup 'target', 'uninstall',
      *toolchain_option(subresource['toolchain']),
      subresource['normalized_name'] || subresource['name']
  end

  # Generate --toolchain option to pass to rustup function
  def toolchain_option(toolchain)
    if toolchain
      ['--toolchain', toolchain]
    else
      []
    end
  end
end
