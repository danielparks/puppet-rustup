# frozen_string_literal: true

require_relative '../../../puppet_x/rustup/provider/collection/components'
require_relative '../../../puppet_x/rustup/provider/collection/targets'
require_relative '../../../puppet_x/rustup/provider/collection/toolchains'
require_relative '../../../puppet_x/rustup/util'
require_relative '../rustup_exec'

Puppet::Type.type(:rustup_internal).provide(
  :default, parent: Puppet::Provider::RustupExec
) do
  desc 'Manage `rustup`.'

  mk_resource_methods

  subresource_collection :toolchains,
    PuppetX::Rustup::Provider::Collection::Toolchains
  subresource_collection :targets,
    PuppetX::Rustup::Provider::Collection::Targets
  subresource_collection :components,
    PuppetX::Rustup::Provider::Collection::Components

  # Get the default toolchain, possibly as requested by the resource.
  #
  # This is necessary for the resource to function properly.
  def default_toolchain
    @property_hash[:default_toolchain] || toolchains.system_default
  end

  # Determine if `rustup` has been installed on the system for this user.
  def exists?
    rustup_installed?
  end

  # The resource thinks we need to install `rustup`.
  def create
    url = URI.parse(resource[:installer_source])

    # Puppet::Util::Execution.execute can’t accept an IO stream or a string as
    # stdin, so we save the script as a file and pipe it into stdin. (We don’t
    # run the script file directly because we cannot guarantee that the user we
    # wish to run it as will have access, even with chmod.)
    PuppetX::Rustup::Util.download(url, ['puppet-rustup-init', '.sh']) do |sh|
      command = ['/bin/sh', '-s', '--', '-y', '--default-toolchain', 'none']
      unless resource[:modify_path]
        command << '--no-modify-path'
      end

      # The default error message for failure would be confusing.
      output = execute(command, stdin_file: sh.path, raise_on_failure: false)
      if output.exitstatus != 0
        raise Puppet::ExecutionFailure, "Installing rustup failed: #{output}"
      end
    end
  end

  # The resource thinks we need to update `rustup`.
  def update
    rustup 'self', 'update'
  end

  # The resource thinks we need to uninstall `rustup`.
  def destroy
    unless user_exists?
      # User doesn’t exist; rely on ensure_absent to delete things.
      return
    end

    # User exists, go ahead and uninstall.
    rustup 'self', 'uninstall', '-y'
  end

  # Normalize toolchain or return the default toolchain for nil.
  #
  # toolchains.list_installed must be run first to get the default toolchain.
  #
  # This *might* return nil if there is somehow no default toolchain. In that
  # case, the nil gets passed along and the toolchain ends up not specified on
  # the command line (see toolchain_option), which means that rustup will figure
  # out what to do.
  def normalize_toolchain_or_default(toolchain)
    if toolchain.nil?
      if resource[:default_toolchain]
        toolchains.normalize(resource[:default_toolchain])
      else
        toolchains.system_default
      end
    else
      toolchains.normalize(toolchain)
    end
  end

  # Memoized version of parse_default_toolchain_triple.
  def default_toolchain_triple
    @default_toolchain_triple ||= parse_default_toolchain_triple
  end

  # Parse default target from `rustup show` for use in toolchain name.
  #
  # Returns partial toolchain descriptor as a 4 element array. The first part
  # should always be "" or nil, but might not be true if rust has added a new
  # platform for the toolchain.
  def parse_default_toolchain_triple
    input = default_target
    if input.nil?
      [nil, nil, nil, nil]
    else
      toolchains.parse_partial("-#{input}")
    end
  end

  # Memoized version of load_default_target
  def default_target
    @default_target || load_default_target
  end

  # Load default target (called “default host”) from `rustup show`.
  #
  # Returns string.
  def load_default_target
    @default_target = nil
    rustup('show').lines.each do |line|
      if line =~ %r{^Default host:\s+(\S+)$}i
        @default_target = Regexp.last_match(1)
        debug { "Got default target: #{@default_target.inspect}" }
        return @default_target
      end
    end

    nil
  end

  protected

  # Ensure it’s really gone.
  #
  # This is called if `ensure` is `absent` even if `exists? == false`.
  def ensure_absent
    # FIXME: use `secure: true`? I’m confused about what the vulnerablity is. It
    # seems to require a world-writable parent directory, but it looks like
    # `secure: true` fails in that case... or maybe that’s all it does?
    FileUtils.rm_rf(resource[:rustup_home])
    FileUtils.rm_rf(resource[:cargo_home])

    if resource[:modify_path]
      # Remove environment changes from shell scripts
      source_line = '. "%s/env"' % cargo_home_str
      rc_files = [
        # FIXME: deal with ZDOTDIR?
        '.zshenv', '.zprofile',
        '.bash_profile', '.bash_login', '.bashrc',
        '.profile'
      ]
      rc_files.each do |rc_file|
        path = File.join(resource[:home], rc_file)
        if File.exist? path
          PuppetX::Rustup::Util.remove_file_line(path, source_line)
        end
      end
    end

    [
      [:toolchains, 'toolchain'],
      [:targets, 'target'],
      [:components, 'component'],
    ].each do |symbol, noun|
      resource[symbol].each do |info|
        if info['ensure'] != 'absent'
          raise Puppet::Error, 'Cannot install %{noun} %{name} for absent ' \
            'rustup installation %{rustup}' % {
              noun: noun,
              name: info[noun].inspect,
              rustup: resource[:title].inspect,
            }
        end
      end
    end
  end

  # Make sure all the bits and pieces are installed.
  #
  # This is called when `ensure` is not `absent`, i.e. `present` or `latest`. It
  # is called even if `exist? == true`.
  def ensure_not_absent
    toolchains.manage(
      resource[:toolchains],
      resource[:purge_toolchains],
      resource[:default_toolchain],
    )
    toolchains.load # Update internal state
    targets.manage(resource[:targets], resource[:purge_targets])
    components.manage(resource[:components], resource[:purge_components])
  end

  # Get cargo_home for use in shell init scripts.
  #
  # Reproduces cargo_home_str() in rustup/src/cli/self_update/shell.rs
  #
  # @see https://github.com/rust-lang/rustup/blob/a441c41679386cf62ebd9e49af6d8b37cd792af6/src/cli/self_update/shell.rs#L54-L68
  def cargo_home_str
    if resource[:cargo_home] == File.join(resource[:home], '.cargo')
      # Special case
      '$HOME/.cargo'
    else
      resource[:cargo_home]
    end
  end
end
