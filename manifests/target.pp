# @summary Install a target for a toolchain
#
# You can name this two ways to automatically set the parameters:
#
#   * `"$rustup: $target $toolchain"`: install `$target` for `$toolchain` for
#     the `rustup` resource named `$rustup` (normally the username). For
#     example, `'daniel: x86_64-unknown-linux-gnu nightly'`.
#   * `"$rustup: $target"`: install `$target` for the default toolchain for
#     the `rustup` resource named `$rustup` (normally the username). For
#     example: `'daniel: stable'`.
#
# @param ensure
#   Whether the target should be present or absent.
# @param rustup
#   The name of the `rustup` installation (normally the username). Automatically
#   set if the `$name` of the resource follows the rules above.
# @param target
#   The name of the target to install, e.g. "sparcv9-sun-solaris". Automatically
#   set if the `$name` of the resource follows the rules above.
# @param toolchain
#   The name of the toolchain in which to install the target, e.g. "stable".
#   `undef` means the default toolchain. Automatically set if the `$name` of the
#   resource follows the rules above.
define rustup::target (
  Enum[present, absent] $ensure    = present,
  String[1]             $rustup    = $name.split(': ')[0],
  String[1]             $target    = $name.split(': ')[1].split(' ')[0],
  Optional[String[1]]   $toolchain = $name.split(': ')[1].split(' ')[1],
) {
  Rustup_internal <| title == $rustup |> {
    targets +> [{
        ensure    => $ensure,
        target    => $target,
        toolchain => $toolchain,
    }],
  }
}
