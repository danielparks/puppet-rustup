# @summary Manage rust with rustup
#
# By default, this uses `curl` to download the installer. Set the `$downloader`
# parameter if you want to use something else.
#
# @param ensure
#   * `present` - install rustup, but don’t update it.
#   * `latest` - install rustup and update it on every puppet run.
#   * `absent` - uninstall rustup and the tools it manages.
# @param user
#   The user to own and manage rustup. We recommend not using root or any other
#   existing user.
# @param manage_user
#   Whether or not to manage the $rustup_user.
# @param home
#   Where to install rustup and the rust toolchains. Will contain rustup and
#   cargo directories.
# @param shell
#   Shell for the rustup user. This can be a nologin shell.
#   ### FIXME test nologin
# @param env_scripts_append
#   Scripts to append with line that sources the cargo environment script.
# @param env_scripts_create
#   Paths that will get links to the cargo environment script.
# @param installer_source
#   URL of the rustup installation script. Only used to set `$downloader`.
# @param downloader
#   Command to download the rustup installation script to stdout.
class rustup (
  Enum[present, latest, absent] $ensure             = present,
  String[1]                     $user               = 'rustup',
  Boolean                       $manage_user        = true,
  String[1]                     $home               = '/opt/rust',
  String[1]                     $shell              = '/bin/bash',
  Array[String[1]]              $env_scripts_append = ['/etc/bash.bashrc'],
  Array[String[1]]              $env_scripts_create = ['/etc/profile.d/99-cargo.sh'],
  String[1]                     $installer_source   = 'https://sh.rustup.rs',
  String[1]                     $downloader         = "curl -sSf ${installer_source}",
) {
  $rustup_home = "${home}/rustup"
  $cargo_home = "${home}/cargo"
  $bin = "${cargo_home}/bin"

  $ensure_simple = $ensure ? {
    absent  => absent,
    default => present,
  }

  if $manage_user {
    group { $user:
      ensure => $ensure_simple,
      system => true,
    }

    user { $user:
      ensure     => $ensure_simple,
      comment    => 'rustup',
      gid        => $user,
      home       => $home,
      managehome => true,
      shell      => $shell,
      system     => true,
    }

    if $ensure == absent {
      # Have to delete the user before its primary group.
      User[$user] -> Group[$user]
    }
  }

  $directory_ensure = $ensure_simple ? {
    present => directory,
    absent  => absent,
  }

  file { [$home, $rustup_home, $cargo_home]:
    ensure => $directory_ensure,
    owner  => $user,
    group  => $user,
    mode   => '0755',
    force  => true,
  }

  # Shell init scripts source this to set the environment correctly.
  file { "${home}/env.sh":
    ensure  => $ensure_simple,
    owner   => $user,
    group   => $user,
    mode    => '0555',
    content => epp('rustup/env.sh.epp', {
      bin         => $bin,
      rustup_home => $rustup_home,
      cargo_home  => $cargo_home,
    }),
  }

  # Modify shell init scripts that don’t follow the profile.d pattern.
  $escaped_env_path = shell_escape("${home}/env.sh")
  $comment = 'cargo env: managed by Puppet'
  $env_scripts_append.each |$path| {
    file_line { "${path} +source ${home}/env.sh":
      ensure            => $ensure_simple,
      path              => $path,
      line              => ". ${escaped_env_path} # ${comment}",
      match             => "^[.] .* # ${comment}\$",
      match_for_absence => true,
    }
  }

  # Add scripts to /etc/profile.d and similar.
  $link_ensure = $ensure_simple ? {
    present => link,
    absent  => absent,
  }

  $env_scripts_create.each |$path| {
    file { $path:
      ensure => $link_ensure,
      owner  => 'root',
      group  => '0',
      mode   => '0444',
      target => "${home}/env.sh"
    }
  }

  # Download and run the actual installer
  if $ensure != absent {
    $install_options = '-y --default-toolchain none --no-modify-path'
    $install_command = "${downloader} | sh -s -- ${install_options}"
    rustup::exec { $install_command:
      creates => "${bin}/rustup",
      tag     => 'rustup-install',
    }
    ->
    # For some reason this doesn’t work with name != $install_command.
    Rustup::Exec <| tag != 'rustup-install' |>

    if $ensure == latest {
      rustup::exec { 'rustup self update':
        tag     => 'rustup-install',
        require => Rustup::Exec[$install_command],
      }
      ->
      Rustup::Exec <| tag != 'rustup-install' |>
    }
  }

  # Targets are installed or removed after toolchains are installed...
  Rustup::Toolchain <| ensure == present |> -> Rustup::Target <| |>
  # ...and before toolchains are removed.
  Rustup::Target <| |> -> Rustup::Toolchain <| ensure == absent |>
}
