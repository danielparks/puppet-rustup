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
rustup { 'user': }
rustup::toolchain { 'user: stable': }
rustup::default { 'user: stable': }
rustup::target { 'user: x86_64-unknown-linux-gnux32': }
rustup::toolchain { 'user: nightly': }
rustup::target { 'user: x86_64-unknown-linux-gnux32 nightly': }
rustup::target { 'user: x86_64-unknown-linux-musl nightly': }
~~~

### Global installation

~~~ puppet
include rustup::global
rustup::toolchain { 'rustup: stable': }
rustup::default { 'rustup: stable': }
rustup::target { 'rustup: x86_64-unknown-linux-gnux32': }
rustup::toolchain { 'rustup: nightly': }
rustup::target { 'rustup: x86_64-unknown-linux-gnux32 nightly': }
rustup::target { 'rustup: x86_64-unknown-linux-musl nightly': }
~~~

## Limitations

This does not support Windows.

## Reference

There is specific documentation for individual parameters in
[REFERENCE.md](REFERENCE.md). That file is generated with:

~~~
pdk bundle exec puppet strings generate --format markdown
~~~
