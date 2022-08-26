# frozen_string_literal: true

require_relative "../rustup_exec"

Puppet::Type.type(:rustup_toolchain).provide(
  :exec, :parent => Puppet::Provider::RustupExec
) do
  desc "Use `rustup` to manage toolchains."

  # Determine if this toolchain has been installed on the system for this user
  def exists?
    make_toolchain_matcher(resource[:toolchain]).match?(
      rustup("toolchain", "list"))
  end

  # There are some flaws in this.
  #
  #   * If you have non-host toolchains (e.g. you run an ARM toolchain on x86_64
  #     under emulation), this may incorrectly match one of them. For example,
  #     if you have stable-aarch64-apple-ios installed on your x86_64 host, this
  #     will match that even though it should not.
  #
  #   * It will break as soon as rust adds a new triple to run toolchains on.
  def make_toolchain_matcher(partial)
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
    re = /\A(.+?)(?:-(#{archs}))?(?:-(#{oses}))?(?:-(#{envs}))?\Z/
    parts = re.match(partial)[1,4].map do |part|
      if part.nil?
        ".+"
      else
        Regexp.escape(part)
      end
    end
    /^#{parts.join('-')}(?: \(default\))?$/
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
