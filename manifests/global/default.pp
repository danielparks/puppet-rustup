# @summary Set default toolchain for global installation
#
# The name should be the name of a toolchain. For example:
#
# ```puppet
# rustup::global::default { 'stable': }
# ```
#
# @param toolchain
#   The name of the toolchain to install, e.g. "stable".
define rustup::global::default (
  String[1] $toolchain = $name,
) {
  include rustup::global

  rustup::default { "${rustup::global::user}: ${name}":
    user        => $rustup::global::user,
    toolchain   => $toolchain,
    home        => $rustup::global::home,
    rustup_home => $rustup::global::rustup_home,
    cargo_home  => $rustup::global::cargo_home,
  }
}
