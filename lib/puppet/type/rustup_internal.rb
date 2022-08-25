# frozen_string_literal: true

require 'puppet/parameter/boolean'

Puppet::Type.newtype(:rustup_internal) do
  @doc = <<~'END',
    @summary Manage a user’s Rust installation with `rustup`

    Use the [`rustup`][#rustup] defined type instead of this.

    The name should be the username.

    **Autorequires:** If Puppet is managing the `user` or the directories
    specified as `cargo_home` and `rustup_home`, then those resources will be
    autorequired.
  END

  # FIXME latest
  ensurable do
    desc <<~'END'
      * `present` - install `rustup`, but don’t update it.
      * `latest` - install `rustup` and update it on every puppet run.
      * `absent` - uninstall `rustup` and the tools it manages.
    END

    defaultto :present
  end

  newparam(:user) do
    isnamevar
    desc 'The user that owns this instance of `rustup`.'

    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, 'User name must be a String not %s.' % value.class
      end
      if value.length == 0
        raise ArgumentError, 'User name is required.'
      end
    end
  end

  autorequire(:user) { self[:user] }

  newparam(:modify_path, :boolean=>true, :parent=>Puppet::Parameter::Boolean) do
    desc <<~'END'
      Whether or not to let `rustup` modify the user’s `PATH` in their shell
      init scripts.
    END
  end

  newproperty(:cargo_home) do
    desc <<~'END'
      Where `cargo` installs executables. Generally you shouldn’t change this.
    END

    validate do |value|
      # need ! value.nil? && ?
      if ! Puppet::Util.absolute_path?(value)
        fail ArgumentError, 'Cargo home must be an absolute path, not "%s"' % value
      end
    end
  end

  autorequire(:file) { self[:cargo_home] }

  newproperty(:rustup_home) do
    desc <<~'END'
      Where toolchains are installed. Generally you shouldn’t change this.
    END

    validate do |value|
      # need ! value.nil? && ?
      if ! Puppet::Util.absolute_path?(value)
        fail ArgumentError, 'Rustup home must be an absolute path, not "%s"' % value
      end
    end
  end

  autorequire(:file) { self[:rustup_home] }

end

#     home: {
#       type: 'Stdlib::Absolutepath',
#       desc: <<~'END',
#         The user’s home directory. This defaults to `/home/$user` on Linux and
#         `/Users/$user` on macOS.
#         END
#       default: '/default', # FIXME
#       behaviour: :init_only, # FIXME? I guess? Maybe it should delete the old one?
#     },
#     bin: {
#       type: 'Stdlib::Absolutepath',
#       desc: <<~'END',
#         Where `rustup` installs proxy executables. Generally you shouldn’t
#         change this.
#         END
#       default: '/default', # FIXME
#       behaviour: :init_only, # FIXME? I guess? Maybe it should delete the old one?
#     },
#     },
#     installer_source: {
#       type: 'Stdlib::HTTPUrl',
#       desc: 'URL of the rustup installation script.',
#       default: 'https://sh.rustup.rs',
#       behaviour: :init_only,
#     },
#   },
