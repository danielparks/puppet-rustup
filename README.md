# Puppet module to manage Rust with `rustup`

This manages [Rust][] installations with the [`rustup` tool][]. There are two
ways to use it:

  * **Per-user installations.** Each user has their own installation in their
    home directory that is entirely separate from every other installation. This
    is how the `rustup` tool expects to be used.
  * **Global installation.** Users are able to access shared toolchains and
    targets, but will not be able to change any of them. Users can still use
    `cargo install`, but the installed tools will only be accessible to
    themselves. The `rustup` tool is not designed to be used this way, but it
    seems to work fine.

## Usage

### Per-user installation

You can just use the [`rustup`][] defined type, or you can define
separate resources for toolchains and targets. You can mix and match these
approaches if you want.

To just install the standard, stable toolchain:

``` puppet
rustup { 'user':
  toolchains => ['stable'],
}
```

A more complicated example:

``` puppet
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
```

This is the multi-resource equivalent of the above, but it always tries to
install the latest nightly toolchain:

``` puppet
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
```

You can find more information in the reference documentation for
[`rustup::toolchain`][] and [`rustup::target`][].

### Global installation

Like the per-user installation this can be configured with one resource (the
[`rustup::global` class][`rustup::global`]) or multiple. Multiple resources
provide more configurability.

``` puppet
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
```

Again, the equivalent configuration except that the nightly toolchain is updated
every run:

``` puppet
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
```

You can find more information in the reference documentation for
[`rustup::global::toolchain`][] and [`rustup::global::target`][].

## Limitations

  * This does not allow management of components.
  * This does not support Windows.

## Reference

See [REFERENCE.md][].

## Development

See [DEVELOPMENT.md][].

[Rust]: https://www.rust-lang.org
[`rustup` tool]: https://rust-lang.github.io/rustup/
[`rustup`]: REFERENCE.md#rustup
[`rustup::toolchain`]: REFERENCE.md#rustup--toolchain
[`rustup::target`]: REFERENCE.md#rustup--target
[`rustup::global`]: REFERENCE.md#rustup--global
[`rustup::global::toolchain`]: REFERENCE.md#rustup--global--toolchain
[`rustup::global::target`]: REFERENCE.md#rustup--global--target
[REFERENCE.md]: REFERENCE.md
[DEVELOPMENT.md]: DEVELOPMENT.md
