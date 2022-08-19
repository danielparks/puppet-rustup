# @summary Install a toolchain
#
# The name of the resource is the name of the toolchain to install.
#
# This cannot reliably check for the presence of a toolchain. It will not
# install the toolchain if another toolchain that matches `$egrep` is already
# installed.
#
# @param ensure
#   Whether the toolchain should be present or absent.
# @param egrep
#   `egrep` compatible regular expression to match the toolchain in the list.
define rustup::toolchain (
  Enum[present, absent] $ensure = present,
  String[1]             $egrep  = "^${name.regsubst('-', '-(.+-)?', 'G')}",
) {
  $toolchain = shell_escape($name)
  $is_installed = "rustup toolchain list | egrep ${shell_escape($egrep)}"

  if $ensure == present {
    rustup::exec { "rustup toolchain install --no-self-update ${toolchain}":
      unless => $is_installed,
    }
  } else {
    rustup::exec { "rustup toolchain uninstall ${toolchain}":
      onlyif => $is_installed,
    }
  }
}
