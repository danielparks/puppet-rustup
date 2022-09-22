# @summary Run a `rustup` command
#
# The name should start with the username followed by a colon and a space, then
# the command. For example:
#
# ```puppet
# rustup::exec { 'daniel: rustup default nightly': }
# ```
#
# @param user
#   The user to run as. Automatically set if the `$name` of the resource follows
#   the rules above.
# @param command
#   The command to run, e.g. 'rustup default stable'. Automatically set if the
#   `$name` of the resource follows the rules above.
# @param creates
#   Only run when if this path does not exist. (See [`exec`] documentation.)
# @param environment
#   Additional environment variables to set beyond `RUSTUP_HOME`, `CARGO_HOME`,
#   and `PATH`.
# @param onlyif
#   Only run when `$onlyif` returns success. (See [`exec`] documentation.)
# @param refreshonly
#   Only run this when it receives an event. (See [`exec`] documentation.)
# @param unless
#   Only run when `$unless` returns failure. (See [`exec`] documentation.)
# @param home
#   The user’s home directory. This defaults to `/home/$user` on Linux and
#   `/Users/$user` on macOS. This is only used to calculate defaults for the
#   `$rustup_home` and `$cargo_home` parameters.
# @param rustup_home
#   Where toolchains are installed. Generally you shouldn’t change this.
# @param cargo_home
#   Where `cargo` installs executables. Generally you shouldn’t change this.
# @param bin
#   Where `rustup` installs proxy executables. Generally you shouldn’t change
#   this.
# @param more
#   Other parameters to pass to exec. They may override any of the other
#   parameters.
#
# [`exec`]: https://puppet.com/docs/puppet/latest/types/exec.html
define rustup::exec (
  String[1]                     $user        = split($name, ': ')[0],
  String[1]                     $command     = split($name, ': ')[1],
  Optional[String[1]]           $creates     = undef,
  Array[String[1]]              $environment = [],
  Rustup::OptionalStringOrArray $onlyif      = undef,
  Boolean                       $refreshonly = false,
  Rustup::OptionalStringOrArray $unless      = undef,
  Stdlib::Absolutepath          $home        = rustup::home($user),
  Stdlib::Absolutepath          $rustup_home = "${home}/.rustup",
  Stdlib::Absolutepath          $cargo_home  = "${home}/.cargo",
  Stdlib::Absolutepath          $bin         = "${cargo_home}/bin",
  Hash[String[1], Any]          $more        = {},
) {
  $params = {
    command     => $command,
    creates     => $creates,
    environment => [
      "RUSTUP_HOME=${rustup_home}",
      "CARGO_HOME=${cargo_home}",
    ] + $environment,
    onlyif      => $onlyif,
    path        => "${bin}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
    refreshonly => $refreshonly,
    'unless'    => $unless,
    user        => $user,
  }

  File <| name == $rustup_home or name == $cargo_home |>
  -> exec { "rustup::exec: ${name}":
    * => $params + $more,
  }

  # Generally exec requires an installation...
  Rustup_internal <| |> -> Exec["rustup::exec: ${name}"]
  # ...except when the installation is being deleted. In that case, the exec
  # probably doesn’t need to run. Making the exec dependent on `rustup` being
  # installed can help:
  #
  #     onlyif => "sh -c 'command -v rustup &>/dev/null' && ...",
}
