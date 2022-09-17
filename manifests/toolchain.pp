# @summary Install a toolchain
#
# The name should start with the name of the `rustup` resource (normally the
# name of the user) followed by a colon and a space, then the toolchain. For
# example:
#
# ```puppet
# rustup::toolchain { 'daniel: stable': }
# ```
#
# @param ensure
#   * `present` - install toolchain if it doesn’t exist, but don’t update it.
#   * `latest` - install toolchain and update it on every puppet run.
#   * `absent` - uninstall toolchain.
# @param rustup
#   The name of the `rustup` installation (normally the username). Automatically
#   set if the `$name` of the resource follows the rules above.
# @param toolchain
#   The name of the toolchain to install, e.g. "stable". Automatically set if
#   the `$name` of the resource follows the rules above.
define rustup::toolchain (
  Enum[present, latest, absent] $ensure    = present,
  String[1]                     $rustup    = $name.split(': ')[0],
  String[1]                     $toolchain = $name.split(': ')[1],
) {
  Rustup_internal <| title == $rustup |> {
    toolchains +> [{
        ensure    => $ensure,
        toolchain => $toolchain,
    }],
  }
}
