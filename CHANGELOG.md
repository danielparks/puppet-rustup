# Change log

All notable changes to this project will be documented in this file.

## main branch

## Release 0.2.1

* Added a section about development status (in slow progress) to [README.md][].
* Updated metadata to support Puppet 8.
* Synced with [PDK][].

[README.md]: README.md
[PDK]: https://www.puppet.com/docs/pdk/2.x/pdk.html

## Release 0.2.0

### Features

* Added `profile` parameter to select which components to include on the initial
  installation of a toolchain. ([PR #10][])
* Added option to install pre-release toolchains. ([PR #11][])
* Added option to make tracing rustup commands easier. ([PR #13][])

### Bug fixes

* Now supports installing non-host toolchains for use with emulators. For
  example, it is now possible to install the `x86_64-pc-windows-gnu` toolchain
  on a Linux host without warnings. ([PR #9][])
* Fixed default values and anchor links in [REFERENCE.md][].
  ([PR #14][], [PR #15][], [PR #20][])

[REFERENCE.md]: REFERENCE.md
[PR #9]: https://github.com/danielparks/puppet-rustup/pull/9
[PR #10]: https://github.com/danielparks/puppet-rustup/pull/10
[PR #11]: https://github.com/danielparks/puppet-rustup/pull/11
[PR #13]: https://github.com/danielparks/puppet-rustup/pull/13
[PR #14]: https://github.com/danielparks/puppet-rustup/pull/14
[PR #15]: https://github.com/danielparks/puppet-rustup/pull/15
[PR #20]: https://github.com/danielparks/puppet-rustup/pull/20


## Release 0.1.0

### Features

* Install [Rust][] via [rustup][].

[Rust]: https://www.rust-lang.org
[rustup]: https://rustup.rs
