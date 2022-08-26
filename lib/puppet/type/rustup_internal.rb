# frozen_string_literal: true

require 'puppet/parameter/boolean'

Puppet::Type.newtype(:rustup_internal) do
  @doc = <<~'END'
    @summary Manage a user’s Rust installation with `rustup`

    Use the [`rustup`][#rustup] defined type instead of this.

    The name should be the username.

    **Autorequires:** If Puppet is managing the `user` or the directories or
    their parents specified as `cargo_home` and `rustup_home`, then those
    resources will be autorequired.
  END

  ensurable do
    desc <<~'END'
      * `present` - install `rustup`, but don’t update it.
      * `latest` - install `rustup` and update it on every puppet run.
      * `absent` - uninstall `rustup` and the tools it manages.
    END

    newvalue :present
    newvalue :latest do
      # FIXME not sure this actually works
      provider.update
    end
    newvalue :absent

    defaultto :present
  end

  newparam(:user) do
    isnamevar
    desc 'The user that owns this instance of `rustup` (autorequired).'

    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, 'User name must be a String not %s.' % value.class
      end
      if value.empty?
        raise ArgumentError, 'User name is required.'
      end
    end
  end

  autorequire(:user) { [self[:user]] }

  newparam(:modify_path, :boolean=>true, :parent=>Puppet::Parameter::Boolean) do
    desc <<~'END'
      Whether or not to let `rustup` modify the user’s `PATH` in their shell
      init scripts. Changing this will have no effect after the initial
      installation.
    END

    defaultto true
  end

  newproperty(:cargo_home) do
    desc <<~'END'
      Where `cargo` installs executables (autorequired). Generally you shouldn’t
      change this.

      Default value: `.cargo` in `user`’s home directory.
    END

    validate do |value|
      # need ! value.nil? && ?
      if ! Puppet::Util.absolute_path?(value)
        fail ArgumentError, 'Cargo home must be an absolute path, not "%s"' % value
      end
    end
  end

  autorequire(:file) { dir_and_parent(self[:cargo_home]) }

  newproperty(:rustup_home) do
    desc <<~'END'
      Where toolchains are installed (autorequired). Generally you shouldn’t
      change this.

      Default value: `.rustup` in `user`’s home directory.
    END

    validate do |value|
      # need ! value.nil? && ?
      if ! Puppet::Util.absolute_path?(value)
        fail ArgumentError, 'Rustup home must be an absolute path, not "%s"' % value
      end
    end
  end

  autorequire(:file) { dir_and_parent(self[:rustup_home]) }

  # rustup may create directories like ~/.cargo, so we want to autorequire their
  # parent directories, too.
  def dir_and_parent(path)
    [path, File::dirname(path)].uniq
  end
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
