# frozen_string_literal: true

# Base class for rustup providers
class Puppet::Provider::RustupExec < Puppet::Provider
  # It’s not really reliable to query rustup installations by user, since they
  # could be installed with CARGO_HOME anywhere.
  def self.instances
    raise Puppet::Error, 'Cannot query rustup installations.'
  end

  # For whatever reason, the resource expected this. An alternate solution is to
  # call mk_resource_methods in child classes, but that adds a bunch more
  # unnecessary methods that modify @property_hash. We don’t use @property_hash
  # at all, since we can just access the resource itself.
  def ensure=(value); end

  # Determine if the resource exists on the system
  def exists?
    raise 'Unimplemented.'
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

  protected

  # Install resource for the first time.
  #
  # Will only be called if both:
  #   * exists? == false
  #   * ensure != :absent
  def install
    raise 'Unimplemented.'
  end

  # Update a previously installed resource.
  #
  # Will only be called if both:
  #   * exists? == true
  #   * ensure == :latest
  def update
    raise 'Unimplemented.'
  end

  # Uninstall a previously installed resource.
  #
  # Will only be called if both:
  #   * exists? == true
  #   * ensure == :absent
  def uninstall
    raise 'Unimplemented.'
  end

  # Run a command as the user
  def execute(command, stdin_file: nil, raise_on_failure: true)
    environment = {
      'PATH' => path_env,
      'RUSTUP_HOME' => resource[:rustup_home],
      'CARGO_HOME' => resource[:cargo_home],
    }

    stdin_message = stdin_file ? " and stdin_file #{stdin_file}" : ''
    debug("Running #{command} for user #{resource[:user]} with environment" \
      " #{environment}#{stdin_message}")

    # FIXME: timeout?
    Puppet::Util::Execution.execute(
      command,
      failonfail: raise_on_failure,
      uid: resource[:user],
      combine: true,
      stdinfile: stdin_file,
      override_locale: false,
      custom_environment: environment,
    )
  end

  # Determine if `rustup` has been installed on the system for this user
  def rustup_installed?
    # FIXME? this actually checks that root can execute the file. Also, it
    # doesn’t check that it’s not a directory.
    File.executable?(rustup_path)
  end

  # Run rustup as the user
  def rustup(*args)
    execute([rustup_path] + args)
  end

  # Get path to rustup binary
  def rustup_path
    File.join(bin_path, 'rustup')
  end

  # Get PATH, including cargo_home/bin
  def path_env
    "#{bin_path}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  end

  # Get path to directory where cargo installs binaries
  def bin_path
    File.join(resource[:cargo_home], 'bin')
  end

  # Output a debugging message
  def debug(message)
    Puppet.debug("#{self.class.resource_type.name}: #{message}")
  end
end
