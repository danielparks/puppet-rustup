# @summary Install a target for a toolchain
#
# You can name this two ways to automatically set the parameters:
#
#   * `"$target $toolchain"`: install `$target` for `$toolchain`. For example,
#     `'x86_64-unknown-linux-gnu nightly'`.
#   * `$target`: install `$target` for the default toolchain.
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
define rustup::target (
  Enum[present, absent] $ensure    = present,
  String[1]             $target    = $name.split(' ')[0],
  Optional[String[1]]   $toolchain = $name.split(' ')[1],
) {
  $filter = $toolchain ? {
    Undef => '',
    String => "--toolchain ${shell_escape($toolchain)}"
  }

  $match = shell_escape("${target} (installed)")
  $is_installed = "rustup target list ${filter} | fgrep -x ${match}"

  if $ensure == present {
    rustup::exec { "rustup target install ${filter} ${shell_escape($target)}":
      unless => $is_installed,
    }
  } else {
    rustup::exec { "rustup target uninstall ${filter} ${shell_escape($target)}":
      onlyif => $is_installed,
    }
  }
}
