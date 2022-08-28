# @summary Install a toolchain
#
# The name should start with the username followed by a colon and a space, then
# the toolchain. For example:
#
# ```puppet
# rustup::toolchain { 'daniel: stable': }
# ```
#
# @param ensure
#   * `present` - install toolchain if it doesn’t exist, but don’t update it.
#   * `latest` - install toolchain and update it on every puppet run.
#   * `absent` - uninstall toolchain.
# @param user
#   The user to install for. Automatically set if the `$name` of the resource
#   follows the rules above.
# @param toolchain
#   The name of the toolchain to install, e.g. "stable". Automatically set if
#   the `$name` of the resource follows the rules above.
# @param home
#   The user’s home directory. This defaults to `/home/$user` on Linux and
#   `/Users/$user` on macOS.
# @param rustup_home
#   Where toolchains are installed. Generally you shouldn’t change this.
# @param cargo_home
#   Where `cargo` installs executables. Generally you shouldn’t change this.
define rustup::toolchain (
  Enum[present, latest, absent] $ensure      = present,
  String[1]                     $user        = $name.split(': ')[0],
  String[1]                     $toolchain   = $name.split(': ')[1],
  Stdlib::Absolutepath          $home        = rustup::home($user),
  Stdlib::Absolutepath          $rustup_home = "${home}/.rustup",
  Stdlib::Absolutepath          $cargo_home  = "${home}/.cargo",
) {
  rustup_toolchain { $name:
    ensure      => $ensure,
    user        => $user,
    toolchain   => $toolchain,
    rustup_home => $rustup_home,
    cargo_home  => $cargo_home,
  }
}
