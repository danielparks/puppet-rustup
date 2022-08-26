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

  def create
    # Puppet::Util::Execution.execute can’t accept an IO stream or a string as
    # stdin, so we save the script as a file.
    script = Tempfile.new(['puppet-rustup-init', '.sh'])
    begin
      download_into(script)
      script.flush()

      command = ["/bin/sh", script.path, "-y", "--default-toolchain", "none"]
      if ! resource[:modify_path]
        command << "--no-modify-path"
      end

      # The default error message for failure would be confusing.
      output = execute(command, resource, raise_on_failure: false)
      if output.exitstatus != 0
        raise Puppet::ExecutionFailure, "Installing rustup failed: #{output}"
      end
    ensure
      script.close()
      script.unlink()
    end
  end

  def update
    execute([rustup(), "self", "update"], resource)
  end

  def destroy
    execute([rustup(), "self", "uninstall", "-y"], resource)
  end

private

  def execute(command, resource, raise_on_failure: true)
    # See https://github.com/puppetlabs/puppet/blob/2b0a129763a4d9f5d861f6ff4ab93b15755a85a6/lib/puppet/provider/exec.rb
    # FIXME timeout?
    Puppet::Util::Execution.execute(
      command,
      :failonfail => raise_on_failure,
      :uid => resource[:user],
      :combine => true,
      :override_locale => false,
      :custom_environment => {
        "PATH" => path_env(),
        "RUSTUP_HOME" => rustup_home(),
        "CARGO_HOME" => cargo_home(),
      },
    )
  end

  def download_into(output)
    url = URI.parse(resource[:installer_source])
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
end


