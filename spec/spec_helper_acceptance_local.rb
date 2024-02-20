# frozen_string_literal: true

def command_global_rustup(params)
  command('sudo -u rustup ' \
    'RUSTUP_HOME=/opt/rust/rustup CARGO_HOME=/opt/rust/cargo ' \
    "/opt/rust/cargo/bin/rustup #{params}")
end

def command_as_user(cmd)
  command("sudo -iu user #{cmd}")
end

def rm_user(name)
  apply_manifest(<<~"END", catch_failures: true)
    user { #{name}:
      ensure => absent,
    }

    file { '#{home}/#{name}':
      ensure => absent,
      force  => true,
    }
  END
end
