# Manage Rust with `rustup`

This manages Rust installations with the `rustup` tool. There are two ways to
use it:

  * With standard, per-user installations. Each user has their own installation
    in their home directory that is entirely separate from every other
    installation.
  * With a global installation. Users are able to access shared toolchains and
    targets, but will not be able to change any of them. Users can still use
    `cargo install`, but the installed tools will only be accessible to
    themselves.

## Usage

### Per user installation

~~~ puppet
rustup { 'user':
  purge_toolchains => true,
  purge_targets    => true,
}
rustup::toolchain { 'user: stable': }
rustup::target { 'user: default': }
rustup::toolchain { 'user: nightly': }
rustup::target { 'user: default nightly': }
rustup::target { 'user: x86_64-unknown-linux-musl nightly': }
~~~

### Global installation

~~~ puppet
class { 'rustup::global':
  purge_toolchains => true,
  purge_targets    => true,
}
rustup::global::toolchain { 'stable': }
rustup::global::target { 'default': }
rustup::global::toolchain { 'nightly': }
rustup::global::target { 'default nightly': }
rustup::global::target { 'x86_64-unknown-linux-musl nightly': }
~~~

## Limitations

  * This does not allow management of components.
  * This does not allow management of profiles.
  * This does not support Windows.

## Reference

There is specific documentation for individual parameters in
[REFERENCE.md](REFERENCE.md). That file is generated with:

~~~
pdk bundle exec puppet strings generate --format markdown
~~~
