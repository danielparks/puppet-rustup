# frozen_string_literal: true

require 'puppet/parameter/boolean'
require_relative '../../puppet_x/rustup/util'
require_relative '../../puppet_x/rustup/property/subresources'

Puppet::Type.newtype(:rustup_internal) do
  @doc = <<~'END'
    @summary Manage a user’s Rust installation with `rustup`

    Use the [`rustup`](#rustup) defined type instead of this.

    The name should be the username.

    **Autorequires:**
      * The `user`.
      * The directory specified by `home`.
      * The directory specified by `cargo_home` and its parent.
      * The directory specified by `rustup_home` and its parent.

    @api private
  END

  # This will consult provider.exists? and determine whether or not to a change
  # has been made based on that (latest will always result in a change).
  ensurable do
    desc <<~'END'
      * `present` - install `rustup`, but don’t update it.
      * `latest` - install `rustup` and update it on every puppet run.
      * `absent` - uninstall `rustup` and the tools it manages.
    END

    newvalue(:present) { provider.create }
    newvalue(:latest) { provider.update }
    newvalue(:absent) { provider.destroy }
    defaultto :present
  end

  newparam(:user) do
    isnamevar
    desc 'The user that owns this instance of `rustup` (autorequired).'

    validate do |value|
      unless PuppetX::Rustup::Util.non_empty_string? value
        raise Puppet::Error, 'User is required to be a non-empty string.'
      end
    end
  end

  autorequire(:user) { [self[:user]] }

  newproperty(:default_toolchain) do
    desc 'Which toolchain should be default.'

    validate do |value|
      unless PuppetX::Rustup::Util.nil_or_non_empty_string? value
        raise Puppet::Error, 'Default_toolchain is required to be undef or a ' \
          'non-empty string.'
      end
    end

    def insync?(is)
      is == provider.toolchains.normalize(should)
    end
  end

  newproperty(:toolchains, parent: PuppetX::Rustup::Property::Subresources) do
    desc <<~'END'
      The toolchains to install, update, or remove.

      Each toolchain must be a Hash with two entries:
        * `ensure`: one of `present`, `latest`, or `absent`
        * `toolchain`: the name of the toolchain
        * `profile`: one of `minimal`, `default`, or `complete`
    END

    validate do |entry|
      # WTF: properties validate each element of a passed array.
      unless entry.is_a?(Hash) && entry.length == 3
        raise Puppet::Error,
          'Expected toolchain Hash with 3 entries, got %s' % entry.inspect
      end

      validate_in(entry, 'ensure', ['present', 'latest', 'absent'])
      validate_non_empty_string(entry, 'toolchain')
      validate_in(entry, 'profile', ['minimal', 'default', 'complete'])
    end

    # Whether or not to ignore toolchains on the system but not in the resource.
    def ignore_removed_entries
      !resource[:purge_toolchains]
    end

    # Do any normalization required for an entry in `should`
    def normalize_should_entry!(entry)
      entry['toolchain'] = provider.toolchains.normalize(entry['toolchain'])
      # `rustup` ignores the profile after the initial install. Thus, the
      # profile key is irrelevant for detecting a change.
      entry.delete('profile')
    end
  end

  newparam(:purge_toolchains, boolean: true,
      parent: Puppet::Parameter::Boolean) do
    desc 'Whether or not to uninstall toolchains that aren’t managed by Puppet.'
    defaultto false
  end

  newproperty(:targets, parent: PuppetX::Rustup::Property::Subresources) do
    desc <<~'END'
      The targets to install or remove.

      Each target must be a Hash with three entries:
        * `ensure`: one of `present` or `absent`
        * `target`: the name of the target
        * `toolchain`: the name of the toolchain or `undef` to indicate the
          default toolchain
    END

    validate do |entry|
      # WTF: properties validate each element of a passed array.
      unless entry.is_a?(Hash) && entry.length == 3
        raise Puppet::Error,
          'Expected target Hash with three entries, got %s' % entry.inspect
      end

      validate_in(entry, 'ensure', ['present', 'absent'])
      validate_non_empty_string(entry, 'target')
      validate_nil_or_non_empty_string(entry, 'toolchain')
    end

    # Whether or not to ignore targets on the system but not in the resource.
    def ignore_removed_entries
      !resource[:purge_targets]
    end

    # Do any normalization required for an entry in `should`
    def normalize_should_entry!(entry)
      entry['toolchain'] = provider.normalize_toolchain_or_default(
        entry['toolchain'],
      )
      entry['target'] = provider.targets.normalize(entry['target'])
    end
  end

  newparam(:purge_targets, boolean: true, parent: Puppet::Parameter::Boolean) do
    desc 'Whether or not to uninstall targets that aren’t managed by Puppet.'
    defaultto false
  end

  newparam(:dist_server) do
    desc <<~'END'
      Override `RUSTUP_DIST_SERVER`. Set to `'https://dev-static.rust-lang.org'`
      to install pre-release toolchains.
    END

    validate do |value|
      # undef is okay, but it doesn’t seem to be passed to this function.
      unless URI.parse(value).absolute?
        # The message is ignored and recreated in the rescue clause.
        raise Puppet::Error
      end
    rescue
      raise Puppet::Error, 'dist_server must be a valid URL, not %s.' \
        % value.inspect
    end
  end

  newparam(:modify_path, boolean: true, parent: Puppet::Parameter::Boolean) do
    desc <<~'END'
      Whether or not to let `rustup` modify the user’s `PATH` in their shell
      init scripts. This only affects the initial installation and removal.
    END

    defaultto true
  end

  newparam(:home) do
    desc <<~'END'
      The user’s home directory (autorequired).

      Default value: `"/home/${user}"`
    END

    # This won’t work on macOS, but then most people will be using the defined
    # type wrapper anyway. This is only really useful with `puppet resource`.
    defaultto { "/home/#{resource[:user]}" }

    validate do |value|
      unless Puppet::Util.absolute_path? value
        raise Puppet::Error, 'User home must be an absolute path, not %s' \
          % value.inspect
      end
    end
  end

  autorequire(:file) { [self[:home]] }

  newparam(:cargo_home) do
    desc <<~'END'
      Where `cargo` installs executables (autorequired). Generally you shouldn’t
      change this.

      Default value: `"${home}/.cargo"`
    END

    defaultto { "#{resource[:home]}/.cargo" }

    validate do |value|
      unless Puppet::Util.absolute_path? value
        raise Puppet::Error, 'Cargo home must be an absolute path, not %s' \
          % value.inspect
      end
    end
  end

  autorequire(:file) { dir_and_parent(self[:cargo_home]) }

  newparam(:rustup_home) do
    desc <<~'END'
      Where toolchains are installed (autorequired). Generally you shouldn’t
      change this.

      Default value: `"${home}/.rustup"`
    END

    defaultto { "#{resource[:home]}/.rustup" }

    validate do |value|
      unless Puppet::Util.absolute_path? value
        raise Puppet::Error, 'Rustup home must be an absolute path, not %s' \
          % value.inspect
      end
    end
  end

  autorequire(:file) { dir_and_parent(self[:rustup_home]) }

  newparam(:installer_source) do
    desc <<~'END'
      URL of the rustup installation script. Changing this will have no effect
      after the initial installation.
    END

    defaultto 'https://sh.rustup.rs'

    validate do |value|
      unless URI.parse(value).absolute?
        # The message is ignored and recreated in the rescue clause.
        raise Puppet::Error
      end
    rescue
      raise Puppet::Error, 'Installer source must be a valid URL, not %s.' \
        % value.inspect
    end
  end

  # rustup may create directories like ~/.cargo, so we want to autorequire their
  # parent directories, too.
  def dir_and_parent(path)
    [path, File.dirname(path)].uniq
  end
end
