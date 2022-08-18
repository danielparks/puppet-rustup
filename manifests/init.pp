# @summary Manage rust with rustup
#
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
# @param rustup_sh_url
#   URL of the rustup installation script.
class rustup (
  Enum[present, absent] $ensure      = present,
  String[1]             $user        = 'rustup',
  Boolean               $manage_user = true,
  String[1]             $home        = '/opt/rust',
  String[1]             $shell       = '/bin/bash',
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
      User[$username] -> Group[$primary_group]
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

  file {
    default:
      ensure => $ensure,
      owner  => $user,
      group  => $user,
      mode   => '0555',
    ;
    # For rustup user, or any user that shouldn't be able to cargo install
    "${home}/cargo-global.env.sh":
      content => epp('rustup/env.sh.epp', {
        paths       => [shell_escape($bin)],
        rustup_home => shell_escape($rustup_home),
        cargo_home  => shell_escape($cargo_home),
      }),
    ;
    # Allow users to cargo install
    "${home}/cargo-local.env.sh":
      content => epp('rustup/env.sh.epp', {
        paths       => [shell_escape($bin), '${HOME}/.cargo/bin'],
        rustup_home => shell_escape($rustup_home),
        cargo_home  => '${HOME}/.cargo/bin',
      }),
    ;
  }

  $escaped_global_env = shell_escape("${home}/cargo-global.env.sh")
  $comment = 'cargo env: managed by Puppet'
  ['.bashrc', '.profile'].each |$file| {
    file_line { "~rustup/${file} source cargo-global.env.sh":
      ensure            => $ensure,
      path              => "${home}/${file}",
      line              => ". ${escaped_global_env} # ${comment}",
      match             => '^[.] .* # ${comment}$',
      match_for_absence => true,
    }
  }
}
