# @summary Manage a user’s Rust installation with `rustup`
#
# The name should be the username.
#
# ```puppet
# rustup { 'daniel': }
# ```
#
# By default, this uses `curl` to download the installer. Set the `$downloader`
# parameter if you want to use something else.
#
# @param ensure
#   * `present` - install rustup, but don’t update it.
#   * `latest` - install rustup and update it on every puppet run.
#   * `absent` - uninstall rustup and the tools it manages.
# @param user
#   The user to own and manage rustup.
# @param home
#   The user’s home directory. This defaults to `/home/$user` on Linux and
#   `/Users/$user` on macOS.
# @param rustup_home
#   Where toolchains are installed. Generally you shouldn’t change this.
# @param cargo_home
#   Where `cargo` installs executables. Generally you shouldn’t change this.
# @param bin
#   Where `rustup` installs proxy executables. Generally you shouldn’t change
#   this.
# @param modify_path
#   Whether or not to let `rustup` modify the user’s `PATH` in their shell init.
# @param installer_source
#   URL of the rustup installation script. Only used to set `$downloader`.
# @param downloader
#   Command to download the rustup installation script to stdout.
define rustup (
  Enum[present, latest, absent] $ensure           = present,
  String[1]                     $user             = $name,
  Stdlib::Absolutepath          $home             = rustup::home($user),
  Stdlib::Absolutepath          $rustup_home      = "${home}/.rustup",
  Stdlib::Absolutepath          $cargo_home       = "${home}/.cargo",
  Stdlib::Absolutepath          $bin              = "${cargo_home}/bin",
  Boolean                       $modify_path      = true,
  String[1]                     $installer_source = 'https://sh.rustup.rs',
  String[1]                     $downloader       = "curl -sSf ${installer_source}",
) {
  if $ensure == absent {
    $command = "${bin}/rustup self uninstall -y"
    rustup::exec { "${user}: ${command}":
      command     => $command,
      user        => $user,
      bin         => $bin,
      rustup_home => $rustup_home,
      cargo_home  => $cargo_home,
      onlyif      => "test -e ${bin}/rustup",
      tag         => 'rustup-uninstall',
    }

    # For some reason this doesn’t work with <| name != ... |>
    Rustup::Exec <| tag != 'rustup-uninstall' |>
    -> Rustup::Exec["${user}: ${command}"]

    Rustup::Exec <| |> ->
    file { [$rustup_home, $cargo_home]:
      ensure => absent,
      force  => true,
    }

    # FIXME it would be nice to be able to enforce this, but we can’t guarantee
    # these files exist. Plus, CentOS uses .bash_profile.
    # if $modify_path {
    #   [".bashrc", ".profile"].each |$file| {
    #     $path = "${home}/${file}"
    #     file_line { "${path} -. \"\$HOME/.cargo/env\"":
    #       ensure            => absent,
    #       path              => $path,
    #       match             => '^[.] "\$HOME/\.cargo/env"$',
    #       match_for_absence => true,
    #     }
    #   }
    # }
  } else {
    # Download and run the actual installer
    $modify_path_option = $modify_path ? {
      true => '',
      false => '--no-modify-path',
    }

    $install_options = "-y --default-toolchain none ${modify_path_option}"
    $install_command = "${downloader} | sh -s -- ${install_options}"
    rustup::exec { "${user}: ${install_command}":
      command     => $install_command,
      user        => $user,
      bin         => $bin,
      rustup_home => $rustup_home,
      cargo_home  => $cargo_home,
      creates     => "${bin}/rustup",
      tag         => 'rustup-install',
    }
    ->
    # For some reason this doesn’t work with <| name != ... |>
    Rustup::Exec <| tag != 'rustup-install' |>

    if $ensure == latest {
      rustup::exec { '${user}: rustup self update':
        tag     => 'rustup-install',
        require => Rustup::Exec["${user}: ${install_command}"],
      }
      ->
      Rustup::Exec <| tag != 'rustup-install' |>
    }

    # Targets are installed or removed after toolchains are installed...
    Rustup::Toolchain <| ensure == present |> -> Rustup::Target <| |>
    # ...and before toolchains are removed.
    Rustup::Target <| |> -> Rustup::Toolchain <| ensure == absent |>
  }
}
