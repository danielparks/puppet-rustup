# frozen_string_literal: true

require_relative '../rustup_exec'
require_relative '../../../puppet_x/rustup/util'

Puppet::Type.type(:rustup_internal).provide(
  :default, parent: Puppet::Provider::RustupExec
) do
  desc 'Manage `rustup`.'

  mk_resource_methods

  def initialize(*)
    super
    @default_toolchain = :unset
  end

  # Either the actual toolchains that exist on the system (see toolchains_real),
  # or the toolchains set with toolchains=
  def toolchains
    @property_hash[:toolchains] || toolchains_real
  end

  # The toolchain list, sorted
  #
  # Used for testing.
  def toolchains_sorted
    toolchains.sort_by { |t| [t['toolchain'], t['ensure']] }
  end

  # Toolchains as they exist on the system (memoized)
  def toolchains_real
    @toolchains_cache || load_toolchains
  end

  # Load toolchains from the system
  #
  # Saves the toolchains to @toolchains_cache.
  def load_toolchains
    @toolchains_cache = toolchain_list.map do |full_name|
      {
        'ensure' => 'present',
        'toolchain' => full_name,
      }
    end
  end

  # Either the default toolchain on the system (see default_toolchain_real), or
  # whatever was set by default_toolchain=
  def default_toolchain
    @property_hash[:default_toolchain] || default_toolchain_real
  end

  # Default toolchain on the system (memoized)
  def default_toolchain_real
    if @default_toolchain == :unset
      load_default_toolchain
    end
    @default_toolchain
  end

  # Load default toolchain from system
  #
  # Uses load_toolchains, which saves the default toolchain to
  # @default_toolchain.
  def load_default_toolchain
    load_toolchains
    @default_toolchain
  end

  # Either the targets on the system (see all_targets_real), or the targets set
  # by targets=
  def targets
    @property_hash[:targets] || all_targets_real
  end

  # The target list, sorted
  #
  # Used for testing.
  def targets_sorted
    targets.sort_by { |t| [t['toolchain'], t['target'], t['ensure']] }
  end

  # Targets for all toolchains as they exist on the system (memoized)
  def all_targets_real
    @targets_cache || load_all_targets
  end

  # Load targets from the system for all toolchains
  #
  # Saves the targets to @targets_cache.
  def load_all_targets
    @targets_cache = toolchains_real.reduce([]) do |combined, info|
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

  # Normalize toolchain name, or return the default toolchain for nil.
  #
  # toolchain_list must be run first in to determine the default toolchain.
  #
  # This *might* return nil if there is somehow no default toolchain. In that
  # case, the nil gets passed along and the toolchain ends up not specified on
  # the command line (see toolchain_option), which means that rustup will figure
  # out what to do.
  def normalize_toolchain(toolchain)
    if toolchain.nil?
      default_toolchain
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

    parts = parse_partial_toolchain(input).map.with_index do |part, i|
      part || default_toolchain_triple[i]
    end
    parts.reject! { |part| part.nil? }
    parts.join('-')
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

  # Memoized version of parse_default_triple.
  #
  # This is used in exists?, which gets called at least twice, and we’d prefer
  # not to call `rustup show` more than we have to.
  def default_toolchain_triple
    @default_toolchain_triple ||= parse_default_triple
  end

  # Parse default “triple” from `rustup show`.
  #
  # Returns partial toolchain descriptor as a 4 element array. The first part
  # should always be "" or nil, but might not be true if rust has added a new
  # platform for the toolchain.
  def parse_default_triple
    input = load_default_triple
    if input.nil?
      [nil, nil, nil, nil]
    else
      parse_partial_toolchain("-#{input}")
    end
  end

  # Load default “triple” from `rustup show`.
  #
  # Returns string.
  def load_default_triple
    rustup('show').lines.each do |line|
      if line =~ %r{^Default host:\s+(\S+)$}i
        triple = Regexp.last_match(1)
        debug { "Got default host (triple): #{triple.inspect}" }
        return triple
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
    unmanaged = toolchain_list
    requested_default = check_default_toolchain(unmanaged)

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
        toolchain_install(info['toolchain'])
      end
    end

    if requested_default && requested_default != @default_toolchain
      rustup 'default', requested_default
      # Probably don’t need to do this
      @default_toolchain = requested_default
    end

    if resource[:purge_toolchains]
      unmanaged.each do |name|
        toolchain_uninstall(name)
      end
    end
  end

  # Load toolchains from system as an array of strings
  #
  # This also sets @default_toolchain.
  def toolchain_list
    @default_toolchain = nil
    unless exists? && user_exists?
      # If rustup isn’t installed, then no toolchains can exist. If the user
      # doesn’t exist then either this resource is ensure => absent and
      # everything will be deleted, or an error will be raised when it tries to
      # install rustup for a non-existent user.
      return []
    end

    lines = rustup('toolchain', 'list').lines(chomp: true).map do |line|
      # delete_suffix! returns nil if there was no suffix.
      @default_toolchain ||= line.delete_suffix!(' (default)')
      line
    end
    lines.delete('no installed toolchains')
    lines
  end

  # Normalize the default_toolchain property and check that it’s valid.
  def check_default_toolchain(unmanaged)
    if @property_hash[:default_toolchain].nil?
      return nil
    end

    default = normalize_toolchain_name(@property_hash[:default_toolchain])

    resource[:toolchains].each do |info|
      if info['toolchain'] == default
        if info['ensure'] == 'absent'
          raise Puppet::Error, "Requested #{default} as default toolchain, " \
            'but also set it to ensure => absent'
        end

        return default
      end
    end

    if resource[:purge_toolchains] || unmanaged.index(default).nil?
      raise Puppet::Error, "Requested #{default} as default toolchain, but " \
        'it is not installed'
    end

    default
  end

  # Install or update a toolchain
  def toolchain_install(toolchain)
    rustup 'toolchain', 'install', '--no-self-update', toolchain
  end

  # Uninstall a toolchain
  def toolchain_uninstall(toolchain)
    rustup 'toolchain', 'uninstall', toolchain
  end

  # Install and uninstall targets as appropriate
  def manage_targets
    # Re-query the installed toolchains after managing them. This is simpler
    # than keeping track. This also sets @default_toolchain.
    installed_toolchains = toolchain_list

    targets_by_toolchain = {}
    resource[:targets].each do |info|
      toolchain = normalize_toolchain(info['toolchain'])

      targets_by_toolchain[toolchain] ||= []
      targets_by_toolchain[toolchain] << {
        ensure: info['ensure'],
        target: info['target'],
      }
    end

    installed_toolchains.each do |toolchain|
      manage_toolchain_targets(
        toolchain,
        targets_by_toolchain.delete(toolchain) || [],
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
