# frozen_string_literal: true

require_relative 'subresources'

# A toolchain subresource collection
class PuppetX::Rustup::Provider::Collection::Toolchains <
    PuppetX::Rustup::Provider::Collection::Subresources
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

  # Get toolchains installed on the system.
  def load
    @system = list_installed.map do |full_name|
      {
        'ensure' => 'present',
        'name' => full_name,
      }
    end
  end

  # Install and uninstall toolchains as appropriate
  #
  # Note that this does not update the internal state after changing the system.
  # You must call toolchains.load after this function if you need the toolchain
  # state to be correct.
  #
  # This takes `resource[:toolchains]` as a parameter instead of using the
  # set value of this collection because the value isn’t set if it is initially
  # unchanged. That means if the values on the system change after `load` was
  # called but before this method was called, we won’t be able to tell.
  def manage(requested, purge, requested_default)
    if requested_default
      requested_default = normalize(requested_default)
      validate_default(requested_default, requested, purge)
    end

    unmanaged = manage_group(system, requested)

    if requested_default
      update_default(requested_default)
    end

    if purge
      uninstall_all(unmanaged)
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
  def normalize(name)
    if name.nil?
      raise ArgumentError, 'normalize expects a string, not nil'
    end

    parse_partial(name)
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
    # From https://github.com/rust-lang/rustup/blob/b3d0bd6be286a6df6de159eede3f38cfd306fd3a/src/dist/triple/known.rs
    # rubocop:disable Style/StringLiterals
    # typos:ignore-start
    archs = [
      "aarch64",
      "aarch64_be",
      "amdgcn",
      "arm",
      "arm64_32",
      "arm64e",
      "arm64ec",
      "armeb",
      "armebv7r",
      "armv4t",
      "armv5te",
      "armv6",
      "armv6k",
      "armv7",
      "armv7a",
      "armv7k",
      "armv7r",
      "armv7s",
      "armv8r",
      "avr",
      "bpfeb",
      "bpfel",
      "csky",
      "hexagon",
      "i386",
      "i586",
      "i686",
      "loongarch64",
      "m68k",
      "mips",
      "mips64",
      "mips64el",
      "mipsel",
      "mipsisa32r6",
      "mipsisa32r6el",
      "mipsisa64r6",
      "mipsisa64r6el",
      "msp430",
      "nvptx64",
      "powerpc",
      "powerpc64",
      "powerpc64le",
      "riscv32",
      "riscv32e",
      "riscv32em",
      "riscv32emc",
      "riscv32gc",
      "riscv32i",
      "riscv32im",
      "riscv32ima",
      "riscv32imac",
      "riscv32imafc",
      "riscv32imc",
      "riscv64",
      "riscv64gc",
      "riscv64imac",
      "s390x",
      "sparc",
      "sparc64",
      "sparcv9",
      "thumbv4t",
      "thumbv5te",
      "thumbv6m",
      "thumbv7a",
      "thumbv7em",
      "thumbv7m",
      "thumbv7neon",
      "thumbv8m.base",
      "thumbv8m.main",
      "wasm32",
      "wasm32v1",
      "wasm64",
      "x86_64",
      "x86_64h",
      "xtensa",
    ].join('|')
    oses = [
      "amd-amdhsa",
      "apple-darwin",
      "apple-ios",
      "apple-tvos",
      "apple-visionos",
      "apple-watchos",
      "esp-espidf",
      "esp32-espidf",
      "esp32-none",
      "esp32s2-espidf",
      "esp32s2-none",
      "esp32s3-espidf",
      "esp32s3-none",
      "fortanix-unknown",
      "ibm-aix",
      "kmc-solid_asp3",
      "linux",
      "lynx-lynxos178",
      "mti-none",
      "nintendo-3ds",
      "nintendo-switch",
      "none",
      "nuttx-eabi",
      "nuttx-eabihf",
      "nvidia-cuda",
      "openwrt-linux",
      "pc-cygwin",
      "pc-nto",
      "pc-solaris",
      "pc-windows",
      "risc0-zkvm",
      "rtems-eabihf",
      "sony-psp",
      "sony-psx",
      "sony-vita",
      "sun-solaris",
      "unikraft-linux",
      "unknown-dragonfly",
      "unknown-emscripten",
      "unknown-freebsd",
      "unknown-fuchsia",
      "unknown-haiku",
      "unknown-hermit",
      "unknown-hurd",
      "unknown-illumos",
      "unknown-l4re",
      "unknown-linux",
      "unknown-netbsd",
      "unknown-none",
      "unknown-nto",
      "unknown-nuttx",
      "unknown-openbsd",
      "unknown-redox",
      "unknown-teeos",
      "unknown-trusty",
      "unknown-uefi",
      "unknown-unknown",
      "unknown-xous",
      "uwp-windows",
      "wali-linux",
      "wasip1",
      "wasip1-threads",
      "wasip2",
      "win7-windows",
      "wrs-vxworks",
    ].join('|')
    envs = [
      "android",
      "androideabi",
      "eabi",
      "eabihf",
      "elf",
      "freestanding",
      "gnu",
      "gnu_ilp32",
      "gnuabi64",
      "gnuabiv2",
      "gnuabiv2hf",
      "gnueabi",
      "gnueabihf",
      "gnullvm",
      "gnuspe",
      "gnux32",
      "macabi",
      "msvc",
      "musl",
      "muslabi64",
      "musleabi",
      "musleabihf",
      "muslspe",
      "newlibeabihf",
      "none",
      "ohos",
      "qnx700",
      "qnx710",
      "qnx710_iosock",
      "qnx800",
      "sgx",
      "sim",
      "softfloat",
      "spe",
      "uclibc",
      "uclibceabi",
      "uclibceabihf",
    ].join('|')
    # typos:ignore-end
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
      normalize(info['name']) == normalized_default
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
      .map do |line|
        toolchain, state = line.split(' ', 2)
        if state
          if %r{\A\(.*\)\z}.match? state
            if state[1..-2].split(%r{,\s*}).include?('default')
              @system_default = toolchain
            end
          else
            raise Puppet::Error,
              "Could not parse line in toolchain list: #{line.inspect}"
          end
        end
        toolchain
      end
  end

  # Install or update a toolchain
  def install(subresource)
    @provider.rustup 'toolchain', 'install', '--no-self-update',
      '--force-non-host', '--profile', subresource['profile'] || 'default',
      subresource['name']
  end

  # Uninstall a toolchain
  def uninstall(subresource)
    @provider.rustup 'toolchain', 'uninstall', subresource['name']
  end
end
