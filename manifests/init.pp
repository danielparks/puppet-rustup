# @summary Manage rust with rustup
#
# @param ensure
#   Whether the rust installation should be present or absent.
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
class rustup (
  Enum[present, absent] $ensure             = present,
  String[1]             $user               = 'rustup',
  Boolean               $manage_user        = true,
  String[1]             $home               = '/opt/rust',
  String[1]             $shell              = '/bin/bash',
  Array[String[1]]      $env_scripts_append = ['/etc/bash.bashrc'],
  Array[String[1]]      $env_scripts_create = ['/etc/profile.d/99-cargo.sh'],
) {
  $rustup_home = "${home}/rustup"
  $cargo_home = "${home}/cargo"
  $bin = "${cargo_home}/bin"

  # Needs variables above
  include rustup::install

  if $manage_user {
    group { $user:
      ensure => $ensure,
      system => true,
    }

    user { $user:
      ensure     => $ensure,
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

  $directory_ensure = $ensure ? {
    present => directory,
    default => $ensure,
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
    ensure  => $ensure,
    owner   => $user,
    group   => $user,
    mode    => '0555',
    content => epp('rustup/env.sh.epp', {
      bin         => $bin,
      rustup_home => $rustup_home,
      cargo_home  => $cargo_home,
    }),
  }

  $escaped_env_path = shell_escape("${home}/env.sh")
  $comment = 'cargo env: managed by Puppet'
  $env_scripts_append.each |$path| {
    file_line { "${path} +source ${home}/env.sh":
      ensure            => $ensure,
      path              => $path,
      line              => ". ${escaped_env_path} # ${comment}",
      match             => "^[.] .* # ${comment}\$",
      match_for_absence => true,
    }
  }

  $link_ensure = $ensure ? {
    present => link,
    default => $ensure,
  }

  $env_scripts_create.each |$path| {
    file { $path:
      ensure => $ensure,
      owner  => 'root',
      group  => '0',
      mode   => '0444',
      target => "${home}/env.sh"
    }
  }
}
