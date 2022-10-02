# Development

## Testing

### Unit tests

```
pdk test unit
```

### Acceptance tests

We use [Puppet Litmus][] with [Docker][] to actually exercise the module.

Note that the acceptance tests are not independent. Installing toolchains is
slow, so it’s practical to have the tests build on each other rather than take
the time to tear them down and rebuild after each individual test.

Testing is easiest to manage with `test.sh`:

```
./test.sh docker-run
```

#### Vagrant

It is also possible to run tests under [Vagrant][], though it is slower. To run
tests under Vagrant for the first time:

```
./test.sh init run
```

To repeat the tests after updating the module:

```
./test.sh fast-init run
```

  * `./test.sh init` — initializes the VMs, installs the module, and creates
    a snapshot called “fresh”.
  * `./test.sh fast-init` — restores the “fresh” snapshot on existing VMs and
    reinstalls the module.
  * `./test.sh run` — run acceptance tests with the _installed_ module. Note
    that if you make changes you will need to reinstall the module with
    `fast-init` or `update`.
  * `./test.sh update` — reinstall the module on the running VMs.
  * `./test.sh destroy` — destroy the VMs. You will need to run `init` again to
    recreate them before doing any further testing.

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
pdk bundle exec puppet strings generate --format markdown && ./fix-reference.rb
```

[Puppet Litmus]: https://github.com/puppetlabs/puppet_litmus
[Docker]: https://www.docker.com
[Vagrant]: https://www.vagrantup.com
[Puppet Strings]: https://github.com/puppetlabs/puppet-strings
[PDK]: https://github.com/puppetlabs/pdk
[REFERENCE.md]: REFERENCE.md
