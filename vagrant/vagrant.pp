rustup::target { 'x86_64-unknown-freebsd stable': }
rustup::target { 'x86_64-unknown-linux-musl nightly': }
rustup::target { 'x86_64-unknown-linux-gnux32 stable':
  ensure => absent,
}
rustup::toolchain { 'stable': }
rustup::toolchain { 'nightly': }
rustup::toolchain { 'beta-x86_64-unknown-linux-gnu':
  ensure => absent,
}

class { 'rustup':
  ensure => latest,
}
