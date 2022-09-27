# @summary Install a target for a toolchain for global installation
#
# You can name this two ways to automatically set the parameters:
#
#   * `"$target $toolchain"`: install `$target` for `$toolchain` in the global
#     installation. For example, `'x86_64-unknown-linux-gnu nightly'`.
#   * `"$target"`: install `$target` for the default toolchain in the global
#     installation. For example: `'stable'`.
#
# @param ensure
#   Whether the target should be present or absent.
# @param target
#   The name of the target to install, e.g. "sparcv9-sun-solaris". Automatically
#   set if the `$name` of the resource follows the rules above.
# @param toolchain
#   The name of the toolchain in which to install the target, e.g. "stable".
#   `undef` means the default toolchain. Automatically set if the `$name` of the
#   resource follows the rules above.
define rustup::global::target (
  Enum[present, absent] $ensure    = present,
  String[1]             $target    = $name.split(' ')[0],
  Optional[String[1]]   $toolchain = $name.split(' ')[1],
) {
  include rustup::global

  rustup::target { "${rustup::global::user}: ${name}":
    ensure    => $ensure,
    rustup    => $rustup::global::user,
    target    => $target,
    toolchain => $toolchain,
  }
}
