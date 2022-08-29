# frozen_string_literal: true

require_relative '../rustup_exec'

Puppet::Type.type(:rustup_internal).provide(
  :shell, parent: Puppet::Provider::RustupExec
) do
  desc 'Run shell-based `rustup` installer on UNIX-like platforms.'

  # Determine if `rustup` has been installed on the system for this user
  def exists?
    rustup_installed?
  end

  protected

  # Install `rustup` for the first time.
  #
  # Will only be called if both:
  #   * exists? == false
  #   * ensure != :absent
  def install
    # Puppet::Util::Execution.execute can’t accept an IO stream or a string as
    # stdin, so we save the script as a file and pipe it into stdin. (We don’t
    # run the script file directly because we cannot guarantee that the user we
    # wish to run it as will have access, even with chmod.)
    script = Tempfile.new(['puppet-rustup-init', '.sh'])
    begin
      url = URI.parse(resource[:installer_source])
      debug("Starting download from #{url} into #{script.path}")
      download_into(url, script)
      script.flush

      command = ['/bin/sh', '-s', '--', '-y', '--default-toolchain', 'none']
      unless resource[:modify_path]
        command << '--no-modify-path'
      end

      # The default error message for failure would be confusing.
      output = execute(command, stdin_file: script.path, raise_on_failure: false)
      if output.exitstatus != 0
        raise Puppet::ExecutionFailure, "Installing rustup failed: #{output}"
      end
    ensure
      debug("Deleting #{script.path}")
      script.close
      script.unlink
    end
  end

  # Update previously installed `rustup`.
  #
  # Will only be called if both:
  #   * exists? == true
  #   * ensure == :latest
  def update
    rustup 'self', 'update'
  end

  # Uninstall previously installed `rustup`.
  #
  # Will only be called if both:
  #   * exists? == true
  #   * ensure == :absent
  def uninstall
    begin
      Etc.getpwnam(resource[:user])
    rescue ArgumentError
      # User doesn’t exist; rely on ensure_absent to delete things.
      return
    end

    # User exists, go ahead and uninstall.
    rustup 'self', 'uninstall', '-y'
  end

  # Ensure it’s really gone.
  #
  # This is called if ensure == :absent even if exists? == false.
  def ensure_absent
    # FIXME use `secure: true`? I’m confused about what the vulnerablity is. It
    # seems to require a world-writable parent directory, but it looks like
    # `secure: true` fails in that case... or maybe that’s all it does?
    FileUtils.rm_rf(resource[:rustup_home])
    FileUtils.rm_rf(resource[:cargo_home])
  end

  # Download a URL into a stream
  def download_into(url, output)
    client = Puppet.runtime[:http]
    client.get(url, options: { include_system_store: true }) do |response|
      unless response.success?
        message = response.body.empty? ? response.reason : response.body
        raise Net::HTTPError.new(
          "Error #{response.code} on SERVER: #{message}",
          Puppet::HTTP::ResponseConverter.to_ruby_response(response),
        )
      end

      response.read_body do |chunk|
        output.print(chunk)
      end
    end
  end
end
