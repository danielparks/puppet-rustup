# frozen_string_literal: true

Puppet::Type.newtype(:rustup_toolchain) do
  @doc = <<~'END'
    @summary Manage a toolchain

    The name should start with the username followed by a colon and a space,
    then the toolchain. For example:

    ```puppet
    rustup::toolchain { 'daniel: stable': }
    ```

    **Autorequires:**
      * The `user`.
      * The `rustup` resource with a name matching `user`.
  END

  ensurable do
    desc <<~'END'
      * `present` - install toolchain, but don’t update it.
      * `latest` - install toolchain and update it on every puppet run.
      * `absent` - uninstall toolchain.
    END

    newvalues :present, :latest, :absent
    defaultto :present
  end

  newparam(:user) do
    isnamevar
    desc 'The user that owns this toolchain (autorequired).'

    validate do |value|
      unless PuppetX::Rustup::Util.non_empty_string? value
        raise Puppet::Error, 'User is required to be a non-empty string.'
      end
    end
  end

  autorequire(:user) { [self[:user]] }
  autorequire(:rustup) { [self[:user]] }

  newparam(:toolchain) do
    isnamevar
    desc 'The toolchain'

    validate do |value|
      unless PuppetX::Rustup::Util.non_empty_string? value
        raise Puppet::Error, 'Toolchain is required to be a non-empty string.'
      end
    end
  end

  validate do
    if !PuppetX::Rustup::Util.non_empty_string? self[:user]
      raise Puppet::Error, 'User is required to be a non-empty string.'
    elsif !PuppetX::Rustup::Util.non_empty_string? self[:toolchain]
      raise Puppet::Error, 'Toolchain is required to be a non-empty string.'
    end
  end

  newparam(:cargo_home) do
    desc <<~'END'
      Where `cargo` installs executables. Generally you shouldn’t change this.

      Default value: `.cargo` in `user`’s home directory.
    END

    # This won’t work on macOS, but then most people will be using the defined
    # type wrapper anyway. This is only really useful with `puppet resource`.
    defaultto { "/home/#{resource[:user]}/.cargo" }

    validate do |value|
      unless Puppet::Util.absolute_path?(value)
        raise Puppet::Error, 'Cargo home must be an absolute path, not "%s"' \
          % value
      end
    end
  end

  newparam(:rustup_home) do
    desc <<~'END'
      Where toolchains are installed. Generally you shouldn’t change this.

      Default value: `.rustup` in `user`’s home directory.
    END

    # This won’t work on macOS, but then most people will be using the defined
    # type wrapper anyway. This is only really useful with `puppet resource`.
    defaultto { "/home/#{resource[:user]}/.rustup" }

    validate do |value|
      unless Puppet::Util.absolute_path?(value)
        raise Puppet::Error, 'Rustup home must be an absolute path, not "%s"' \
          % value
      end
    end
  end

  def self.title_patterns
    [
      [
        %r{\A(.+?): (.+)\Z},
        [
          [ :user ],
          [ :toolchain ],
        ],
      ],
      # Allow title to be non-structured as long as parameters are set. Accepts
      # an empty string because the error for a missing toolchain is better than
      # “No set of title patterns matched…”
      [
        %r{\A(.*?)\Z},
        [
          [ :toolchain ],
        ],
      ],
    ]
  end
end
