# @summary Run a rustup command
#
# @param command
#   The command to run, e.g. 'rustup default stable'.
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
# @param more
#   Other parameters to pass to exec. They may override any of the other
#   parameters.
#
# [`exec`]: https://puppet.com/docs/puppet/latest/types/exec.html
define rustup::exec (
  String[1]                                   $command     = $name,
  Optional[String[1]]                         $creates     = undef,
  Array[String[1]]                            $environment = [],
  Variant[Undef, Array[String[1]], String[1]] $onlyif      = undef,
  Boolean                                     $refreshonly = false,
  Variant[Undef, Array[String[1]], String[1]] $unless      = undef,
  Hash[String[1], Any]                        $more        = {},
) {
  include rustup

  $params = {
    command     => $command,
    creates     => $creates,
    environment => [
      "RUSTUP_HOME=${rustup::rustup_home}",
      "CARGO_HOME=${rustup::cargo_home}",
    ] + $environment,
    onlyif      => $onlyif,
    path        => "${rustup::bin}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
    refreshonly => $refreshonly,
    'unless'    => $unless,
    user        => $rustup::user,
    require     => File[$rustup::rustup_home, $rustup::cargo_home],
  }

  exec { "rustup::exec: ${name}":
    * => $params + $more,
  }
}
