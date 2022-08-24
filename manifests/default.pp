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
define rustup::default (
  String[1] $user      = $name.split(': ')[0],
  String[1] $toolchain = $name.split(': ')[1],
) {
  $expected_output = "^${toolchain}(-.*)? [(]default[)]\$"
  $command = "rustup default ${shell_escape($toolchain)}"

  Rustup::Toolchain <| |> ->
  rustup::exec { "${user}: ${command}":
    command => $command,
    user    => $user,
    unless  => "rustup default | egrep ${shell_escape($expected_output)}",
  }
}
