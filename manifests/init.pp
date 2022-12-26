# @summary Manage a user’s Rust installation with `rustup`
#
# The name should be the username.
#
# @example Standard usage
#   rustup { 'daniel': }
#
# @param ensure
#   * `present` - install rustup, but don’t update it.
#   * `latest` - install rustup and update it on every puppet run.
#   * `absent` - uninstall rustup and the tools it manages.
# @param user
#   The user to own and manage rustup.
# @param default_toolchain
#   Which toolchain should be the default.
# @param toolchains
#   The toolchains to install.
# @param purge_toolchains
#   Whether or not to uninstall toolchains that aren’t managed by Puppet.
# @param targets
#   The targets to install. These can take two forms:
#
#     * `"$target $toolchain"`: Install `$target` for `$toolchain`.
#     * `"$target"`: Install `$target` for the default toolchain.
#
#   You can use `'default'` to indicate the target for the current host.
# @param purge_targets
#   Whether or not to uninstall targets that aren’t managed by Puppet.
# @param dist_server
#   Override `RUSTUP_DIST_SERVER`. Set to `'https://dev-static.rust-lang.org'`
#   to install pre-release toolchains.
# @param home
#   The user’s home directory. This defaults to `/home/$user` on Linux and
#   `/Users/$user` on macOS.
# @param rustup_home
#   Where toolchains are installed. Generally you shouldn’t change this.
# @param cargo_home
#   Where `cargo` installs executables. Generally you shouldn’t change this.
# @param modify_path
#   Whether or not to let `rustup` modify the user’s `PATH` in their shell init
#   scripts. This only affects the initial installation and removal.
# @param installer_source
#   URL of the rustup installation script. Changing this will have no effect
#   after the initial installation.
define rustup (
  Enum[present, latest, absent] $ensure            = present,
  String[1]                     $user              = $name,
  Optional[String[1]]           $default_toolchain = undef,
  Array[String[1]]              $toolchains        = [],
  Boolean                       $purge_toolchains  = false,
  Array[String[1]]              $targets           = [],
  Boolean                       $purge_targets     = false,
  Optional[Stdlib::HTTPUrl]     $dist_server       = undef,
  Stdlib::Absolutepath          $home              = rustup::home($user),
  Stdlib::Absolutepath          $rustup_home       = "${home}/.rustup",
  Stdlib::Absolutepath          $cargo_home        = "${home}/.cargo",
  Boolean                       $modify_path       = true,
  Stdlib::HTTPUrl               $installer_source  = 'https://sh.rustup.rs',
) {
  if $ensure == absent {
    $_toolchains = []
    $_targets = []
  } else {
    $_toolchains = $toolchains.map |$toolchain| {
      {
        ensure  => present,
        name    => $toolchain,
        profile => 'default',
      }
    }

    $_targets = $targets.map |$target| {
      {
        ensure    => present,
        target    => $target.split(' ')[0],
        toolchain => $target.split(' ')[1],
      }
    }
  }

  rustup_internal { $name:
    ensure            => $ensure,
    user              => $user,
    default_toolchain => $default_toolchain,
    toolchains        => $_toolchains,
    purge_toolchains  => $purge_toolchains,
    targets           => $_targets,
    purge_targets     => $purge_targets,
    dist_server       => $dist_server,
    home              => $home,
    rustup_home       => $rustup_home,
    cargo_home        => $cargo_home,
    modify_path       => $modify_path,
    installer_source  => $installer_source,
  }
}
