# @summary Manage a user’s Rust installation with `rustup`
#
# The name should be the username.
#
# @example Standard usage
#   rustup { 'daniel': }
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
# @param modify_path
#   Whether or not to let `rustup` modify the user’s `PATH` in their shell init
#   scripts. Changing this will have no effect after the initial installation.
# @param installer_source
#   URL of the rustup installation script. Changing this will have no effect
#   after the initial installation.
define rustup (
  Enum[present, latest, absent] $ensure           = present,
  String[1]                     $user             = $name,
  Stdlib::Absolutepath          $home             = rustup::home($user),
  Stdlib::Absolutepath          $rustup_home      = "${home}/.rustup",
  Stdlib::Absolutepath          $cargo_home       = "${home}/.cargo",
  Boolean                       $modify_path      = true,
  Stdlib::HTTPUrl               $installer_source = 'https://sh.rustup.rs',
) {
  rustup_internal { $name:
    ensure           => $ensure,
    user             => $user,
    rustup_home      => $rustup_home,
    cargo_home       => $cargo_home,
    modify_path      => $modify_path,
    installer_source => $installer_source,
  }

  if $ensure == absent {
    Rustup::Exec <| |> ->
    Rustup_internal[$name] ->
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
    Rustup_internal[$name] ->
    Rustup::Exec <| |>

    # Targets are installed or removed after toolchains are installed...
    Rustup::Toolchain <| ensure == present |> -> Rustup::Target <| |>
    # ...and before toolchains are removed.
    Rustup::Target <| |> -> Rustup::Toolchain <| ensure == absent |>
  }
}
