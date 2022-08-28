# @summary Install a target for a toolchain
#
# You can name this two ways to automatically set the parameters:
#
#   * `"$user: $target $toolchain"`: install `$target` for `$toolchain` for
#     `$user`. For example, `'daniel: x86_64-unknown-linux-gnu nightly'`.
#   * `"$user: $target"`: install `$target` for the default toolchain for
#     `$user`. For example: `'daniel: stable'`.
#
# @param ensure
#   Whether the target should be present or absent.
# @param user
#   The user to install for. Automatically set if the `$name` of the resource
#   follows the rules above.
# @param target
#   The name of the target to install, e.g. "sparcv9-sun-solaris". Automatically
#   set if the `$name` of the resource follows the rules above.
# @param toolchain
#   The name of the toolchain in which to install the target, e.g. "stable".
#   `undef` means the default toolchain. Automatically set if the `$name` of the
#   resource follows the rules above.
# @param home
#   The user’s home directory. This defaults to `/home/$user` on Linux and
#   `/Users/$user` on macOS. This is only used to calculate defaults for the
#   `$rustup_home` and `$cargo_home` parameters.
# @param rustup_home
#   Where toolchains are installed. Generally you shouldn’t change this.
# @param cargo_home
#   Where `cargo` installs executables. Generally you shouldn’t change this.
define rustup::target (
  Enum[present, absent] $ensure      = present,
  String[1]             $user        = $name.split(': ')[0],
  String[1]             $target      = $name.split(': ')[1].split(' ')[0],
  Optional[String[1]]   $toolchain   = $name.split(': ')[1].split(' ')[1],
  Stdlib::Absolutepath  $home        = rustup::home($user),
  Stdlib::Absolutepath  $rustup_home = "${home}/.rustup",
  Stdlib::Absolutepath  $cargo_home  = "${home}/.cargo",
) {
  $filter = $toolchain ? {
    Undef => '',
    String => "--toolchain ${shell_escape($toolchain)}"
  }

  $match = shell_escape("${target} (installed)")
  $is_installed = "rustup target list ${filter} | fgrep -x ${match}"

  if $ensure == present {
    $command = "rustup target install ${filter} ${shell_escape($target)}"
    rustup::exec { "${user}: ${command}":
      command     => $command,
      user        => $user,
      unless      => $is_installed,
      rustup_home => $rustup_home,
      cargo_home  => $cargo_home,
    }
  } else {
    $command = "rustup target uninstall ${filter} ${shell_escape($target)}"
    rustup::exec { "${user}: ${command}":
      command     => $command,
      user        => $user,
      onlyif      => $is_installed,
      rustup_home => $rustup_home,
      cargo_home  => $cargo_home,
    }
  }
}
