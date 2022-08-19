# Manage Rust with rustup

## Usage

~~~ puppet
rustup::toolchain { 'stable': }
rustup::target { 'x86_64-unknown-linux-gnux32': }
rustup::toolchain { 'nightly': }
rustup::target { 'x86_64-unknown-linux-gnux32 nightly': }
rustup::target { 'x86_64-unknown-linux-musl nightly': }
~~~

## Limitations

This does not support Windows.

## Reference

There is specific documentation for individual parameters in
[REFERENCE.md](REFERENCE.md). That file is generated with:

~~~
pdk bundle exec puppet strings generate --format markdown
~~~
