# @summary Install rustup
#
# By default, this uses `curl`. Set the `$downloader` parameter if you want to
# use something else.
#
# You generally should not need to use this directly; `rustup` includes it. If
# you need to change the parameters you can either use hiera, or declare this
# class after `include rustup`.
#
# @param source
#   URL of the rustup installation script. Only used to set `$downloader`.
# @param downloader
#   Command to download the rustup installation script to stdout.
class rustup::install (
  String[1] $source     = 'https://sh.rustup.rs',
  String[1] $downloader = "curl -sSf ${source}",
) {
  include rustup

  if $rustup::ensure == present {
    $install_options = '-y --default-toolchain none --no-modify-path'
    rustup::exec { "${downloader} | sh -s -- ${install_options}":
      creates => "${rustup::bin}/rustup",
    }
  }
}
