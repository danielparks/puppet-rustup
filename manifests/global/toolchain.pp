# @summary Install a toolchain for global installation
#
# The name should just be the toolchain. For example:
#
# ```puppet
# rustup::global::toolchain { 'stable': }
# ```
#
# @param ensure
#   * `present` - install toolchain if it doesn’t exist, but don’t update it.
#   * `latest` - install toolchain and update it on every puppet run.
#   * `absent` - uninstall toolchain.
# @param toolchain
#   The name of the toolchain to install, e.g. "stable".
define rustup::global::toolchain (
  Enum[present, latest, absent] $ensure    = present,
  String[1]                     $toolchain = $name,
) {
  include rustup::global

  rustup::toolchain { "${rustup::global::user}: ${name}":
    ensure      => $ensure,
    user        => $rustup::global::user,
    toolchain   => $toolchain,
    home        => $rustup::global::home,
    rustup_home => $rustup::global::rustup_home,
    cargo_home  => $rustup::global::cargo_home,
  }
}
