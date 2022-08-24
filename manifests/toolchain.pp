# @summary Install a toolchain
#
# The name should start with the username followed by a colon and a space, then
# the toolchain. For example:
#
# ```puppet
# rustup::toolchain { 'daniel: stable': }
# ```
#
# This cannot reliably check for the presence of a toolchain. It will not
# install the toolchain if another toolchain that matches `$egrep` is already
# installed.
#
# @param ensure
#   Whether the toolchain should be present or absent.
# @param user
#   The user to install for. Automatically set if the `$name` of the resource
#   follows the rules above.
# @param toolchain
#   The name of the toolchain to install, e.g. "stable". Automatically set if
#   the `$name` of the resource follows the rules above.
# @param egrep
#   `egrep` compatible regular expression to match the toolchain in the list.
define rustup::toolchain (
  Enum[present, absent] $ensure    = present,
  String[1]             $user      = $name.split(': ')[0],
  String[1]             $toolchain = $name.split(': ')[1],
  String[1]             $egrep     = "^${toolchain.regsubst('-', '-(.+-)?', 'G')}",
) {
  $is_installed = "rustup toolchain list | egrep ${shell_escape($egrep)}"

  if $ensure == present {
    $command = "rustup toolchain install --no-self-update ${shell_escape($toolchain)}"
    rustup::exec { "${user}: ${command}":
      command => $command,
      user    => $user,
      unless  => $is_installed,
    }
  } else {
    $command = "rustup toolchain uninstall ${shell_escape($toolchain)}"
    rustup::exec { "${user}: ${command}":
      command => $command,
      user    => $user,
      onlyif  => $is_installed,
    }
  }
}
