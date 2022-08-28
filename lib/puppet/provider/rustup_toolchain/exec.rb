# frozen_string_literal: true

require_relative "../rustup_exec"

Puppet::Type.type(:rustup_toolchain).provide(
  :exec, :parent => Puppet::Provider::RustupExec
) do
  desc "Use `rustup` to manage toolchains."

  # Determine if this toolchain has been installed on the system for this user
  def exists?
    rustup_installed? &&
    make_toolchain_matcher(resource[:toolchain]).match?(
      rustup("toolchain", "list"))
  end

  # There are some flaws in this.
  #
  #   * This is kludged together. I didn’t take the time to figure out all the
  #     edge cases that rustup deals with.
  #
  #   * It will break as soon as rust adds a new triple to run toolchains on.
  #
  # public for testing
  def make_toolchain_matcher(input)
    parts = parse_partial_toolchain(input).map.with_index do |part, i|
      if part.nil?
        default_toolchain_triple()[i]
      else
        Regexp.escape(part)
      end
    end
    parts.select! { |part| !part.nil? }
    /^#{parts.join('-')}(?: \(default\))?$/
  end

  # Parse a partial toolchain descriptor into its parts.
  #
  # FIXME this will break as soon as Rust adds a new platform for the toolchain
  # to run on.
  def parse_partial_toolchain(input)
    # From https://github.com/rust-lang/rustup/blob/6bc5d2c340e1dd9880b68564a19f0dea384c849c/src/dist/triple.rs
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
    re = /\A(.*?)(?:-(#{archs}))?(?:-(#{oses}))?(?:-(#{envs}))?\Z/
    match = re.match(input)
    if match.nil?
      [nil, nil, nil, nil]
    else
      match[1,4]
    end
  end

  # Memoized version of parse_default_triple.
  #
  # This is used in exists?, which gets called at least twice, and we’d prefer
  # not to call `rustup show` more than we have to.
  def default_toolchain_triple
    @default_toolchain_triple ||= parse_default_triple()
  end

  # Parse default “triple” from `rustup show`.
  #
  # Returns partial toolchain descriptor as a 4 element array. The first part
  # should always be "" or nil, but might not be true if rust has added a new
  # platform for the toolchain.
  def parse_default_triple
    input = load_default_triple()
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
    rustup("show").split(/[\r\n]+/).each do |line|
      if line =~ /^Default host:\s+(\S+)$/i
        debug("Got default host (triple): #{$1}")
        return $1
      end
    end

    nil
  end

protected

  # Install toolchain for the first time.
  #
  # Will only be called if both:
  #   * exists? == false
  #   * ensure != :absent
  def install
    rustup "toolchain", "install", "--no-self-update", resource[:toolchain]
  end

  # Update previously installed `rustup`.
  #
  # Will only be called if both:
  #   * exists? == true
  #   * ensure == :latest
  def update
    install
  end

  # Uninstall a previously installed toolchain.
  #
  # Will only be called if both:
  #   * exists? == true
  #   * ensure == :absent
  def uninstall
    rustup "toolchain", "uninstall", resource[:toolchain]
  end
end
