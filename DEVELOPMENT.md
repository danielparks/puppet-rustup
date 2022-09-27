# Development

## Testing

### Unit tests

```
pdk test unit
```

### Acceptance tests

We use [Puppet Litmus][] with [Docker][] to actually exercise the module:

```
./test.sh init run destroy
```

Docker must be installed and running for the above to work. If you prefer, you
can use [Vagrant][] instead by specifying `--vagrant`, though I’ve found that
it’s poorly supported with Puppet Litmus.

See `./test.sh --help` for more information.

Note that the acceptance tests are not independent. Installing toolchains is
slow, so it’s practical to have the tests build on each other rather than take
the time to tear them down and rebuild after each individual test.

## Debugging

To see what the module is doing under the hood, you can set the `RUSTUP_TRACE`
environment variable and run puppet with verbose mode:

```
$ RUSTUP_TRACE= puppet apply --verbose -e 'rustup { "daniel": }'
Info: Loading facts
Notice: Compiled catalog for marlow.local in environment production in 0.05 seconds
Info: Using environment 'production'
Info: Applying configuration version '1663673350'
Info: rustup_internal: as daniel: /Users/daniel/.cargo/bin/rustup toolchain list
Info: rustup_internal: as daniel: /Users/daniel/.cargo/bin/rustup target list --toolchain stable-x86_64-apple-darwin
Info: rustup_internal: as daniel: /Users/daniel/.cargo/bin/rustup target list --toolchain nightly-x86_64-apple-darwin
Notice: Applied catalog in 0.22 seconds
```

## Documentation

[Reference documentation][REFERENCE.md] is generated with [Puppet Strings][] (as
part of [PDK][]).

```
pdk bundle exec puppet strings generate --format markdown
```

[Puppet Litmus]: https://github.com/puppetlabs/puppet_litmus
[Docker]: https://www.docker.com
[Vagrant]: https://www.vagrantup.com
[Puppet Strings]: https://github.com/puppetlabs/puppet-strings
[PDK]: https://github.com/puppetlabs/pdk
[REFERENCE.md]: REFERENCE.md
