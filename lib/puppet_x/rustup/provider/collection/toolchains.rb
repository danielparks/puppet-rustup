# frozen_string_literal: true

require_relative 'subresources'

# A toolchain subresource collection
class PuppetX::Rustup::Provider::Collection::Toolchains <
    PuppetX::Rustup::Provider::Collection::Subresources
  plural_name 'Toolchains'

  def initialize(provider)
    super
    @system_default = :unset
  end

  # Get the real default toolchain on the system
  def system_default
    if @system_default == :unset
      load
    end
    @system_default
  end

  # Is the passed toolchain already installed?
  #
  # @param [String] normalized toolchain name
  # @return [Boolean]
  def installed?(toolchain)
    system.any? { |info| info['toolchain'] == toolchain }
  end

  # Get toolchains installed on the system.
  def load
    @system = list_installed.map do |full_name|
      {
        'ensure' => 'present',
        'toolchain' => full_name,
      }
    end
  end

  # Install and uninstall toolchains as appropriate
  #
  # Note that this does not update the internal state after changing the system.
  # You must call toolchains.load after this function if you need the toolchain
  # state to be correct.
  def manage(requested, purge, requested_default)
    if requested_default
      requested_default = normalize(requested_default)
      validate_default(requested_default, requested, purge)
    end

    unmanaged = system.map { |info| info['toolchain'] }

    # Use `resource[:toolchains]` instead of the `toolchains` method because the
    # result of the `toolchains` method can change if the resource requested
    # the same toolchains as existed on the system, and then the toolchains on
    # the system changed.
    requested.each do |info|
      full_name = normalize(info['toolchain'])

      # Look for toolchain in list of installed, unmanaged toolchains. Note
      # that this could be a problem if we specify a toolchain twice (e.g.
      # "stable" and "stable-x86_64-apple-darwin").
      found = unmanaged.delete(full_name)

      if info['ensure'] == 'absent'
        if found
          uninstall(info['toolchain'])
        end
      elsif found.nil? || info['ensure'] == 'latest'
        install(info['toolchain'], profile: info['profile'])
      end
    end

    if requested_default
      update_default(requested_default)
    end

    if purge
      unmanaged.each do |name|
        uninstall(name)
      end
    end
  end

  # Normalize a toolchain (not nil).
  #
  # There are some flaws in this.
  #
  #   * This is kludged together. I didn’t take the time to figure out all the
  #     edge cases that rustup deals with.
  #
  #   * It will break as soon as rust adds a new triple to run toolchains on.
  def normalize(input)
    if input.nil?
      raise ArgumentError, 'normalize expects a string, not nil'
    end

    parse_partial(input)
      .map
      .with_index { |part, i| part || @provider.default_toolchain_triple[i] }
      .compact
      .join('-')
  end

  # Parse a partial toolchain descriptor into its parts.
  #
  # FIXME: this will break as soon as Rust adds a new platform for the toolchain
  # to run on.
  def parse_partial(input)
    # From https://github.com/rust-lang/rustup/blob/732feb8a733a6ad5c56cd9b637b501e8fa54491e/src/dist/triple.rs
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
      "loongarch64",
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

  # Validate that the default toolchain is or will be installed
  def validate_default(normalized_default, requested_toolchains, purge)
    found = requested_toolchains.find do |info|
      normalize(info['toolchain']) == normalized_default
    end

    if found
      if found['ensure'] == 'absent'
        raise Puppet::Error, "Requested #{normalized_default.inspect} as " \
          'default toolchain, but also set it to ensure => absent'
      end
    elsif !installed?(normalized_default)
      raise Puppet::Error, "Requested #{normalized_default.inspect} as " \
        'default toolchain, but it is not installed'
    elsif purge
      raise Puppet::Error, "Requested #{normalized_default.inspect} as " \
        'default toolchain, but it is being purged'
    end
  end

  # Save default toolchain to system
  def update_default(toolchain)
    if toolchain != @system_default
      @provider.rustup 'default', toolchain
      @system_default = toolchain
    end
  end

  # Load installed toolchains from system as an array of strings
  #
  # This also sets @system_default.
  def list_installed
    @system_default = nil
    unless @provider.exists? && @provider.user_exists?
      # If rustup isn’t installed, then no toolchains can exist. If the user
      # doesn’t exist then either this resource is ensure => absent and
      # everything will be deleted, or an error will be raised when it tries to
      # install rustup for a non-existent user.
      return []
    end

    @provider.rustup('toolchain', 'list')
      .lines(chomp: true)
      .reject { |line| line == 'no installed toolchains' }
      .each do |line|
        # delete_suffix! returns nil if there was no suffix.
        if line.delete_suffix!(' (default)')
          @system_default = line
        end
      end
  end

  # Install or update a toolchain
  def install(toolchain, profile: 'default')
    @provider.rustup 'toolchain', 'install', '--no-self-update',
      '--force-non-host', '--profile', profile, toolchain
  end

  # Uninstall a toolchain
  def uninstall(toolchain)
    @provider.rustup 'toolchain', 'uninstall', toolchain
  end
end
