# frozen_string_literal: true

require 'puppet/parameter/boolean'

Puppet::Type.newtype(:rustup_internal) do
  @doc = <<~'END'
    @summary Manage a user’s Rust installation with `rustup`

    Use the [`rustup`](#rustup) defined type instead of this.

    The name should be the username.

    **Autorequires:**
      * The `user`.
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
      if !value.is_a?(String) || value.empty?
        raise Puppet::Error, 'User is required to be a non-empty string.'
      end
    end
  end

  autorequire(:user) { [self[:user]] }

  newparam(:modify_path, boolean: true, parent: Puppet::Parameter::Boolean) do
    desc <<~'END'
      Whether or not to let `rustup` modify the user’s `PATH` in their shell
      init scripts. Changing this will have no effect after the initial
      installation.
    END

    defaultto true
  end

  newparam(:cargo_home) do
    desc <<~'END'
      Where `cargo` installs executables (autorequired). Generally you shouldn’t
      change this.

      Default value: `.cargo` in `user`’s home directory.
    END

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

      Default value: `.rustup` in `user`’s home directory.
    END

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
      if !value.is_a?(String) || value.empty?
        raise Puppet::Error, 'Installer source must be a valid URL, not "%s".' \
          % value
      end
      begin
        URI.parse(value)
      rescue
        raise Puppet::Error, 'Installer source must be a valid URL, not "%s".' \
          % value
      end
    end
  end

  # rustup may create directories like ~/.cargo, so we want to autorequire their
  # parent directories, too.
  def dir_and_parent(path)
    [path, File.dirname(path)].uniq
  end
end
