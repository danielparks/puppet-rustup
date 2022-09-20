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
# @param profile
#   Profile to use for installation. This determines which components will be
#   installed initially.
#
#   Changing this for an existing installation will not have an effect even if
#   it causes an update, i.e. when `ensure => latest` is set.
define rustup::global::toolchain (
  Enum[present, latest, absent] $ensure    = present,
  String[1]                     $toolchain = $name,
  Rustup::Profile               $profile   = 'default',
) {
  include rustup::global

  rustup::toolchain { "${rustup::global::user}: ${name}":
    ensure    => $ensure,
    rustup    => $rustup::global::user,
    toolchain => $toolchain,
    profile   => $profile,
  }
}
