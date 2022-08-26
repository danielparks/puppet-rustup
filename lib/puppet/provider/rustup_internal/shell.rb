# frozen_string_literal: true

Puppet::Type.type(:rustup_internal).provide(:shell) do
  desc "Run shell-based `rustup` installer on UNIX-like platforms."

  mk_resource_methods

  # It’s not really reliable to query rustup installations by user, since they
  # could be installed with CARGO_HOME anywhere.
  def self.instances
    fail Puppet::Error, "Cannot query rustup installations."
  end

  def cargo_home
    resource[:cargo_home] || File.join(home(), ".cargo")
  end

  def rustup_home
    resource[:rustup_home] || File.join(home(), ".rustup")
  end

  def exists?
    # FIXME? this actually checks that root can execute the file. Also, it
    # doesn’t check that it’s not a directory.
    File.executable?(rustup())
  end

  # Changes have been made to the resource; apply them.
  def flush
    if exists?
      if resource[:ensure] == :absent
        uninstall
      elsif resource[:ensure] == :latest
        update
      end
    elsif resource[:ensure] != :absent
      # Does not exist, but should.
      install
    end
  end

private

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
      script.flush()

      command = %w{/bin/sh -s -- -y --default-toolchain none}
      if ! resource[:modify_path]
        command << "--no-modify-path"
      end

      # The default error message for failure would be confusing.
      output = execute(command, stdin_file: script.path, raise_on_failure: false)
      if output.exitstatus != 0
        raise Puppet::ExecutionFailure, "Installing rustup failed: #{output}"
      end
    ensure
      debug("Deleting #{script.path}")
      script.close()
      script.unlink()
    end
  end

  def update
    execute([rustup(), "self", "update"])
  end

  def uninstall
    execute([rustup(), "self", "uninstall", "-y"])
  end

  def execute(command, stdin_file: nil, raise_on_failure: true)
    environment = {
      "PATH" => path_env(),
      "RUSTUP_HOME" => rustup_home(),
      "CARGO_HOME" => cargo_home(),
    }

    stdin_message = stdin_file ? " and stdin_file #{stdin_file}" : ""
    debug("Running #{command} for user #{resource[:user]} with environment #{environment}#{stdin_message}")

    # FIXME timeout?
    Puppet::Util::Execution.execute(
      command,
      :failonfail => raise_on_failure,
      :uid => resource[:user],
      :combine => true,
      :stdinfile => stdin_file,
      :override_locale => false,
      :custom_environment => environment,
    )
  end

  def download_into(url, output)
    client = Puppet.runtime[:http]
    client.get(url, options: {include_system_store: true}) do |response|
      if ! response.success?
        message = response.body.empty? ? response.reason : response.body
        raise Net::HTTPError.new(
          "Error #{response.code} on SERVER: #{message}",
          Puppet::HTTP::ResponseConverter.to_ruby_response(response))
      end

      response.read_body do |chunk|
        output.print(chunk)
      end
    end
  end

  def rustup
    File.join(bin(), "rustup")
  end

  def path_env
    "#{bin()}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  end

  def bin
    File.join(cargo_home(), "bin")
  end

  def home
    Etc.getpwnam(resource[:user]).dir
  end

  def debug(message)
    Puppet.debug("rustup_internal: #{message}")
  end
end


