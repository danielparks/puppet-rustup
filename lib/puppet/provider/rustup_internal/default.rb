# frozen_string_literal: true

require 'puppet/provider/rustup_exec'
require 'puppet_x/rustup/util'

Puppet::Type.type(:rustup_internal).provide(
  :default, parent: Puppet::Provider::RustupExec
) do
  desc 'Manage `rustup`.'

  mk_resource_methods

  subresource_collection :toolchains do
    toolchain_list.map do |full_name|
      {
        'ensure' => 'present',
        'toolchain' => full_name,
      }
    end
  end

  subresource_collection :targets do
    system_toolchains.reduce([]) do |combined, info|
      toolchain = info['toolchain']
      combined + target_list(toolchain).map do |target|
        {
          'ensure' => 'present',
          'target' => target,
          'toolchain' => toolchain,
        }
      end
    end
  end

  def initialize(*)
    super
    @system_default_toolchain = :unset
  end

  # Get the real default toolchain on the system
  def system_default_toolchain
    if @system_default_toolchain == :unset
      load_toolchains
    end
    @system_default_toolchain
  end

  # Get the default toolchain, possibly as requested by the resource.
  #
  # This is necessary for the resource to function properly.
  def default_toolchain
    @property_hash[:default_toolchain] || system_default_toolchain
  end

  # Is the passed toolchain already installed?
  #
  # @param [String] normalized toolchain name
  # @return [Boolean]
  def toolchain_installed?(toolchain)
    system_toolchains.any? { |info| info['toolchain'] == toolchain }
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

  # Normalize toolchain specified for a target, or return the default toolchain
  # for nil.
  #
  # toolchain_list must be run first in to determine the default toolchain.
  #
  # This *might* return nil if there is somehow no default toolchain. In that
  # case, the nil gets passed along and the toolchain ends up not specified on
  # the command line (see toolchain_option), which means that rustup will figure
  # out what to do.
  def normalize_target_toolchain(toolchain)
    if toolchain.nil?
      normalize_default_toolchain_requested || system_default_toolchain
    else
      normalize_toolchain_name(toolchain)
    end
  end

  # Normalize a toolchain name (not nil).
  #
  # There are some flaws in this.
  #
  #   * This is kludged together. I didn’t take the time to figure out all the
  #     edge cases that rustup deals with.
  #
  #   * It will break as soon as rust adds a new triple to run toolchains on.
  #
  # public for testing
  def normalize_toolchain_name(input)
    if input.nil?
      raise ArgumentError, 'normalize_toolchain_name expects a string, not nil'
    end

    parse_partial_toolchain(input)
      .map.with_index { |part, i| part || default_toolchain_triple[i] }
      .compact
      .join('-')
  end

  # Normalize target.
  def normalize_target(target)
    if target == 'default'
      default_target
    else
      target
    end
  end

  # Parse a partial toolchain descriptor into its parts.
  #
  # FIXME this will break as soon as Rust adds a new platform for the toolchain
  # to run on.
  def parse_partial_toolchain(input)
    # From https://github.com/rust-lang/rustup/blob/6bc5d2c340e1dd9880b68564a19f0dea384c849c/src/dist/triple.rs
    # rubocop:disable Style/StringLiterals
    archs = [
      "i386",
      "i586",
      "i686",
      "x86_64",
      "arm",
      "armv7",
      "armv7s",
      "aarch64",
      "mips",
      "mipsel",
      "mips64",
      "mips64el",
      "powerpc",
      "powerpc64",
      "powerpc64le",
      "riscv64gc",
      "s390x",
    ].join('|')
    oses = [
      "pc-windows",
      "unknown-linux",
      "apple-darwin",
      "unknown-netbsd",
      "apple-ios",
      "linux",
      "rumprun-netbsd",
      "unknown-freebsd",
      "unknown-illumos",
    ].join('|')
    envs = [
      "gnu",
      "gnux32",
      "msvc",
      "gnueabi",
      "gnueabihf",
      "gnuabi64",
      "androideabi",
      "android",
      "musl",
    ].join('|')
    # rubocop:enable Style/StringLiterals
    re = %r{\A(.*?)(?:-(#{archs}))?(?:-(#{oses}))?(?:-(#{envs}))?\Z}
    match = re.match(input)
    if match.nil?
      [nil, nil, nil, nil]
    else
      match[1, 4]
    end
  end

  # Memoized version of parse_default_target.
  def default_toolchain_triple
    @default_toolchain_triple ||= parse_default_target
  end

  # Parse default target from `rustup show` for use in toolchain name.
  #
  # Returns partial toolchain descriptor as a 4 element array. The first part
  # should always be "" or nil, but might not be true if rust has added a new
  # platform for the toolchain.
  def parse_default_target
    input = default_target
    if input.nil?
      [nil, nil, nil, nil]
    else
      parse_partial_toolchain("-#{input}")
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

    resource[:toolchains].each do |toolchain|
      if toolchain['ensure'] != 'absent'
        raise Puppet::Error, 'Cannot install toolchain %{toolchain} for ' \
          'absent rustup installation %{rustup}' % {
            toolchain: toolchain['toolchain'].inspect,
            rustup: resource[:title].inspect,
          }
      end
    end

    resource[:targets].each do |target|
      if target['ensure'] != 'absent'
        raise Puppet::Error, 'Cannot install target %{target} for absent ' \
          'rustup installation %{rustup}' % {
            target: target['target'].inspect,
            rustup: resource[:title].inspect,
          }
      end
    end
  end

  # Make sure all the bits and pieces are installed.
  #
  # This is called when `ensure` is not `absent`, i.e. `present` or `latest`. It
  # is called even if `exist? == true`.
  def ensure_not_absent
    manage_toolchains
    manage_targets
  end

  # Install and uninstall toolchains as appropriate
  def manage_toolchains
    requested_default = normalize_default_toolchain_requested
    if requested_default
      validate_default_toolchain(requested_default)
    end

    unmanaged = system_toolchains.map { |info| info['toolchain'] }

    # Use `resource[:toolchains]` instead of the `toolchains` method because the
    # result of the `toolchains` method can change if the resource requested
    # the same toolchains as existed on the system, and then the toolchains on
    # the system changed.
    resource[:toolchains].each do |info|
      full_name = normalize_toolchain_name(info['toolchain'])

      # Look for toolchain in list of installed, unmanaged toolchains. Note
      # that this could be a problem if we specify a toolchain twice (e.g.
      # "stable" and "stable-x86_64-apple-darwin").
      found = unmanaged.delete(full_name)

      if info['ensure'] == 'absent'
        if found
          toolchain_uninstall(info['toolchain'])
        end
      elsif found.nil? || info['ensure'] == 'latest'
        toolchain_install(info['toolchain'], profile: info['profile'])
      end
    end

    if requested_default && requested_default != system_default_toolchain
      rustup 'default', requested_default
      # Probably don’t need to do this
      @system_default_toolchain = requested_default
    end

    if resource[:purge_toolchains]
      unmanaged.each do |name|
        toolchain_uninstall(name)
      end
    end
  end

  # Load toolchains from system as an array of strings
  #
  # This also sets @system_default_toolchain.
  def toolchain_list
    @system_default_toolchain = nil
    unless exists? && user_exists?
      # If rustup isn’t installed, then no toolchains can exist. If the user
      # doesn’t exist then either this resource is ensure => absent and
      # everything will be deleted, or an error will be raised when it tries to
      # install rustup for a non-existent user.
      return []
    end

    lines = rustup('toolchain', 'list').lines(chomp: true).map do |line|
      # delete_suffix! returns nil if there was no suffix.
      if line.delete_suffix!(' (default)')
        @system_default_toolchain = line
      end
      line
    end
    lines.delete('no installed toolchains')
    lines
  end

  # Normalize the requested default_toolchain and check that it’s valid.
  #
  # This uses `resource[:default_toolchain]` because we want to check what was
  # requested by the resource. `@property_hash[:default_toolchain]` doesn’t work
  # because it’s not set if the resource doesn’t detect a change, and using the
  # `default_toolchain` method doesn’t work if it’s not set on resource AND the
  # old default_toolchain is being deleted.
  def normalize_default_toolchain_requested
    if resource[:default_toolchain].nil?
      return nil
    end

    normalize_toolchain_name(resource[:default_toolchain])
  end

  # Validate that the default toolchain is or will be installed
  def validate_default_toolchain(normalized_default)
    found = resource[:toolchains].find do |info|
      normalize_toolchain_name(info['toolchain']) == normalized_default
    end

    if found
      if found['ensure'] == 'absent'
        raise Puppet::Error, "Requested #{normalized_default.inspect} as " \
          'default toolchain, but also set it to ensure => absent'
      end
    elsif !toolchain_installed?(normalized_default)
      raise Puppet::Error, "Requested #{normalized_default.inspect} as " \
        'default toolchain, but it is not installed'
    elsif resource[:purge_toolchains]
      raise Puppet::Error, "Requested #{normalized_default.inspect} as " \
        'default toolchain, but it is being purged'
    end
  end

  # Install or update a toolchain
  def toolchain_install(toolchain, profile: 'default')
    rustup 'toolchain', 'install', '--no-self-update', '--force-non-host', \
      '--profile', profile, toolchain
  end

  # Uninstall a toolchain
  def toolchain_uninstall(toolchain)
    rustup 'toolchain', 'uninstall', toolchain
  end

  # Install and uninstall targets as appropriate
  def manage_targets
    # Re-query the installed toolchains after managing them. This is simpler
    # than keeping track. This also sets @system_default_toolchain.
    installed_toolchains = load_toolchains

    targets_by_toolchain = {}
    resource[:targets].each do |info|
      toolchain = normalize_target_toolchain(info['toolchain'])
      target = normalize_target(info['target'])

      targets_by_toolchain[toolchain] ||= []
      targets_by_toolchain[toolchain] << {
        ensure: info['ensure'],
        target: target,
      }
    end

    installed_toolchains.each do |info|
      manage_toolchain_targets(
        info['toolchain'],
        targets_by_toolchain.delete(info['toolchain']) || [],
      )
    end

    # Find targets that were requested for uninstalled toolchains.
    errors = targets_by_toolchain.map do |toolchain, targets|
      if targets.any? { |target| target[:ensure] != 'absent' }
        toolchain
      else
        nil
      end
    end

    errors.compact!
    unless errors.empty?
      raise Puppet::Error, 'Targets were requested for toolchains that are ' \
        "not installed: #{errors.join(', ')}"
    end
  end

  # Manage targets for a particular toolchain
  def manage_toolchain_targets(toolchain, targets)
    unmanaged = target_list(toolchain)

    targets.each do |info|
      found = unmanaged.delete(info[:target])
      if info[:ensure] == 'absent'
        if found
          target_uninstall(info[:target], toolchain: toolchain)
        end
      elsif found.nil?
        # ensure == 'present' implied
        target_install(info[:target], toolchain: toolchain)
      end
    end

    if resource[:purge_targets]
      unmanaged.each do |target|
        target_uninstall(target, toolchain: toolchain)
      end
    end
  end

  # Get list of installed targets for a toolchain
  def target_list(toolchain)
    rustup('target', 'list', *toolchain_option(toolchain))
      .lines(chomp: true) \
      # delete_suffix! returns nil if there was no suffix
      .map { |line| line.delete_suffix!(' (installed)') }
      .compact
  end

  # Install a target
  def target_install(target, toolchain: nil)
    rustup 'target', 'install', *toolchain_option(toolchain), target
  end

  # Uninstall a target
  def target_uninstall(target, toolchain: nil)
    rustup 'target', 'uninstall', *toolchain_option(toolchain), target
  end

  # Generate --toolchain option to pass to rustup function
  def toolchain_option(toolchain)
    if toolchain.nil?
      []
    else
      ['--toolchain', toolchain]
    end
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
