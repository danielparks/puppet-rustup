# Manage Rust with `rustup`

This manages Rust installations with the [`rustup`][] tool. There are two ways
to use it:

  * With standard, per-user installations. Each user has their own installation
    in their home directory that is entirely separate from every other
    installation.
  * With a global installation. Users are able to access shared toolchains and
    targets, but will not be able to change any of them. Users can still use
    `cargo install`, but the installed tools will only be accessible to
    themselves.

## Usage

### Per-user installation

You can just use the `rustup` resource, or you can define separate resources for
toolchains and targets. You can mix and match these approaches if you want.

To just install the standard, stable toolchain:

~~~ puppet
rustup { 'user':
  toolchains => ['stable'],
}
~~~

A more complicated example:

~~~ puppet
rustup { 'user':
  toolchains       => ['stable', 'nightly'],
  targets          => [
    'default stable',
    'default nightly',
    'x86_64-unknown-linux-musl nightly',
  ],
  purge_toolchains => true,
  purge_targets    => true,
}
~~~

This is the multi-resource equivalent of the above, but it always tries to
install the latest nightly toolchain:

~~~ puppet
rustup { 'user':
  purge_toolchains => true,
  purge_targets    => true,
}
rustup::toolchain { 'user: stable': }
rustup::target { 'user: default': }
rustup::toolchain { 'user: nightly':
  ensure => latest,
}
rustup::target { 'user: default nightly': }
rustup::target { 'user: x86_64-unknown-linux-musl nightly': }
~~~

### Global installation

Like the per-user installation this can be configured with one resource or
multiple. Multiple resources provide more configurability.

~~~ puppet
class { 'rustup::global':
  toolchains       => ['stable', 'nightly'],
  targets          => [
    'default stable',
    'default nightly',
    'x86_64-unknown-linux-musl nightly',
  ],
  purge_toolchains => true,
  purge_targets    => true,
}
~~~

Again, the equivalent configuration except that the nightly toolchain is updated
every run:

~~~ puppet
class { 'rustup::global':
  purge_toolchains => true,
  purge_targets    => true,
}
rustup::global::toolchain { 'stable': }
rustup::global::target { 'default': }
rustup::global::toolchain { 'nightly':
  ensure => latest,
}
rustup::global::target { 'default nightly': }
rustup::global::target { 'x86_64-unknown-linux-musl nightly': }
~~~

### Debugging

To see what the module is doing under the hood, you can set the `RUSTUP_TRACE`
environment variable and run puppet with verbose mode:

~~~
$ RUSTUP_TRACE= puppet apply --verbose -e 'rustup { "daniel": }'
Info: Loading facts
Notice: Compiled catalog for marlow.local in environment production in 0.05 seconds
Info: Using environment 'production'
Info: Applying configuration version '1663673350'
Info: rustup_internal: as daniel: /Users/daniel/.cargo/bin/rustup toolchain list
Info: rustup_internal: as daniel: /Users/daniel/.cargo/bin/rustup target list --toolchain stable-x86_64-apple-darwin
Info: rustup_internal: as daniel: /Users/daniel/.cargo/bin/rustup target list --toolchain nightly-x86_64-apple-darwin
Notice: Applied catalog in 0.22 seconds
~~~

## Limitations

  * This does not allow management of components.
  * This does not support Windows.

## Reference

There is specific documentation for individual parameters in
[REFERENCE.md](REFERENCE.md). That file is generated with:

~~~
pdk bundle exec puppet strings generate --format markdown
~~~


[`rustup`]: https://rust-lang.github.io/rustup/
