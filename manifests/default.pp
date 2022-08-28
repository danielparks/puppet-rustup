# @summary Set default toolchain
#
# The name should start with the username followed by a colon and a space, then
# the toolchain. For example:
#
# ```puppet
# rustup::default { 'daniel: stable': }
# ```
#
# @param user
#   The user to install for. Automatically set if the `$name` of the resource
#   follows the rules above.
# @param toolchain
#   The name of the toolchain to install, e.g. "stable". Automatically set if
#   the `$name` of the resource follows the rules above.
# @param home
#   The user’s home directory. This defaults to `/home/$user` on Linux and
#   `/Users/$user` on macOS. This is only used to calculate defaults for the
#   `$rustup_home` and `$cargo_home` parameters.
# @param rustup_home
#   Where toolchains are installed. Generally you shouldn’t change this.
# @param cargo_home
#   Where `cargo` installs executables. Generally you shouldn’t change this.
define rustup::default (
  String[1]            $user        = $name.split(': ')[0],
  String[1]            $toolchain   = $name.split(': ')[1],
  Stdlib::Absolutepath $home        = rustup::home($user),
  Stdlib::Absolutepath $rustup_home = "${home}/.rustup",
  Stdlib::Absolutepath $cargo_home  = "${home}/.cargo",
) {
  $expected_output = "^${toolchain}(-.*)? [(]default[)]\$"
  $command = "rustup default ${shell_escape($toolchain)}"

  Rustup::Toolchain <| |> ->
  rustup::exec { "${user}: ${command}":
    command     => $command,
    user        => $user,
    unless      => "rustup default | egrep ${shell_escape($expected_output)}",
    rustup_home => $rustup_home,
    cargo_home  => $cargo_home,
  }
}
