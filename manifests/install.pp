# @summary Install rustup
#
# Requires curl or wget
#
# @param ensure
#   Whether to install or uninstall (`present` or `absent`, respectively).
# @param source
#   URL of the rustup installation script. Only used to set `$downloader`.
# @param downloader
#   Command to download the rustup installation script to stdout.
class rustup::install (
  Enum[present, absent] $ensure     = present,
  String[1]             $source     = 'https://sh.rustup.rs',
  String[1]             $downloader = "curl -sSf ${source}",
) {
  include rustup

  if $ensure == present {
    exec { "${downloader} | sh -s -- -y --default-toolchain none --no-modify-path":
      creates     => "${rustup::bin}/rustup",
      environment => [
        "RUSTUP_HOME=${rustup::rustup_home}",
        "CARGO_HOME=${rustup::cargo_home}",
      ],
      # $rustup::bin should not even exist yet
      path        => "${rustup::bin}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
      user        => $rustup::user,
      require     => File[$rustup::rustup_home, $rustup::cargo_home],
    }
  }
}
