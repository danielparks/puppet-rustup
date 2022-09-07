# frozen_string_literal: true

require 'puppet/parameter/boolean'

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
  END

  ensurable do
    desc <<~'END'
      * `present` - install `rustup`, but don’t update it.
      * `latest` - install `rustup` and update it on every puppet run.
      * `absent` - uninstall `rustup` and the tools it manages.
    END

    newvalues :present, :latest, :absent
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
      unless Puppet::Util.absolute_path?(value)
        raise Puppet::Error, 'User home must be an absolute path, not "%s"' \
          % value
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
      unless Puppet::Util.absolute_path?(value)
        raise Puppet::Error, 'Cargo home must be an absolute path, not "%s"' \
          % value
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
      unless Puppet::Util.absolute_path?(value)
        raise Puppet::Error, 'Rustup home must be an absolute path, not "%s"' \
          % value
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
      unless PuppetX::Rustup::Util.non_empty_string?(value) \
          && URI.parse(value).absolute?
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
