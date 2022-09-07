# frozen_string_literal: true

require_relative '../rustup_exec'
require_relative '../../../puppet_x/rustup/util'

Puppet::Type.type(:rustup_internal).provide(
  :shell, parent: Puppet::Provider::RustupExec
) do
  desc 'Run shell-based `rustup` installer on UNIX-like platforms.'

  # Determine if `rustup` has been installed on the system for this user.
  def exists?
    rustup_installed?
  end

  # The resource thinks we need to install `rustup`.
  def create
    url = URI.parse(resource[:installer_source])

    # Puppet::Util::Execution.execute can’t accept an IO stream or a string as
    # stdin, so we save the script as a file and pipe it into stdin. (We don’t
    # run the script file directly because we cannot guarantee that the user we
    # wish to run it as will have access, even with chmod.)
    PuppetX::Rustup::Util.download(url, ['puppet-rustup-init', '.sh']) do |sh|
      command = ['/bin/sh', '-s', '--', '-y', '--default-toolchain', 'none']
      unless resource[:modify_path]
        command << '--no-modify-path'
      end

      # The default error message for failure would be confusing.
      output = execute(command, stdin_file: sh.path, raise_on_failure: false)
      if output.exitstatus != 0
        raise Puppet::ExecutionFailure, "Installing rustup failed: #{output}"
      end
    end
  end

  # The resource thinks we need to update `rustup`.
  def update
    rustup 'self', 'update'
  end

  # The resource thinks we need to uninstall `rustup`.
  def destroy
    begin
      Etc.getpwnam(resource[:user])
    rescue ArgumentError
      # User doesn’t exist; rely on ensure_absent to delete things.
      return
    end

    # User exists, go ahead and uninstall.
    rustup 'self', 'uninstall', '-y'
  end

  protected

  # Ensure it’s really gone.
  #
  # This is called if ensure == :absent even if exists? == false.
  def ensure_absent
    # FIXME: use `secure: true`? I’m confused about what the vulnerablity is. It
    # seems to require a world-writable parent directory, but it looks like
    # `secure: true` fails in that case... or maybe that’s all it does?
    FileUtils.rm_rf(resource[:rustup_home])
    FileUtils.rm_rf(resource[:cargo_home])

    if resource[:modify_path]
      # Remove environment changes from shell scripts
      source_line = '. "%s/env"' % cargo_home_str
      rc_files = [
        # FIXME: deal with ZDOTDIR?
        '.zshenv', '.zprofile',
        '.bash_profile', '.bash_login', '.bashrc',
        '.profile'
      ]
      rc_files.each do |rc_file|
        path = File.join(resource[:home], rc_file)
        if File.exist? path
          PuppetX::Rustup::Util.remove_file_line(path, source_line)
        end
      end
    end
  end

  # Get cargo_home for use in shell init scripts.
  #
  # Reproduces cargo_home_str() in rustup/src/cli/self_update/shell.rs
  #
  # @see https://github.com/rust-lang/rustup/blob/a441c41679386cf62ebd9e49af6d8b37cd792af6/src/cli/self_update/shell.rs#L54-L68
  def cargo_home_str
    if resource[:cargo_home] == File.join(resource[:home], '.cargo')
      # Special case
      '$HOME/.cargo'
    else
      resource[:cargo_home]
    end
  end
end
