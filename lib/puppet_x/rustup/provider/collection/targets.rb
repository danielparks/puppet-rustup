# frozen_string_literal: true

require_relative 'subresources'

# A target subresource collection
class PuppetX::Rustup::Provider::Collection::Targets <
    PuppetX::Rustup::Provider::Collection::Subresources
  # Get targets installed on the system.
  def load
    @system = @provider.toolchains.system.reduce([]) do |combined, info|
      toolchain_name = info['name']
      combined + list_installed(toolchain_name).map do |target_name|
        {
          'ensure' => 'present',
          'name' => target_name,
          'toolchain' => toolchain_name,
        }
      end
    end
  end

  # Install and uninstall targets as appropriate
  #
  # Note that this does not update the internal state after changing the system.
  # You must call targets.load after this function if you need the target state
  # to be correct.
  def manage(requested, purge)
    system_grouped = system.group_by { |info| info['toolchain'] }
    group_subresources_by_toolchain(requested) do |toolchain, infos|
      unmanaged = (system_grouped[toolchain] || []).map { |info| info['name'] }

      infos.each do |info|
        target = normalize(info['name'])

        found = unmanaged.delete(target)
        if info['ensure'] == 'absent'
          if found
            uninstall(target, toolchain: toolchain)
          end
        elsif found.nil?
          # ensure == 'present' implied
          install(target, toolchain: toolchain)
        end
      end

      if purge
        unmanaged.each do |target|
          uninstall(target, toolchain: toolchain)
        end
      end
    end
  end

  # Normalize target.
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
  def install(target, toolchain: nil)
    @provider.rustup 'target', 'install', *toolchain_option(toolchain), target
  end

  # Uninstall a target
  def uninstall(target, toolchain: nil)
    @provider.rustup 'target', 'uninstall', *toolchain_option(toolchain), target
  end

  # Generate --toolchain option to pass to rustup function
  def toolchain_option(toolchain)
    if toolchain.nil?
      []
    else
      ['--toolchain', toolchain]
    end
  end
end
