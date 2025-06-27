# frozen_string_literal: true

# Base class for rustup providers
class Puppet::Provider::RustupExec < Puppet::Provider
  # It’s not really reliable to query rustup installations by user, since they
  # could be installed with CARGO_HOME anywhere.
  def self.instances
    raise Puppet::Error, 'Cannot query rustup installations.'
  end

  # Add a subresource that gets managed somewhat separately
  def self.subresource_collection(name, klass)
    name = name.to_sym

    # Get current subresources
    define_method(name) do
      @subresource_collections[name] ||= klass.new(self)
    end

    # Set current subresources
    define_method("#{name}=") do |values|
      @subresource_collections[name].values = values
    end
  end

  def initialize(*)
    super
    @subresource_collections = {}
  end

  # Determine if the resource exists on the system.
  def exists?
    raise 'Unimplemented.'
  end

  # The resource thinks we need to create it on the system.
  #
  # This is called from the `ensurable` block on the resource, e.g:
  #     newvalue(:present) { provider.create }
  def create
    raise 'Unimplemented.'
  end

  # The resource thinks we need to update it on the system.
  #
  # This is called from the `ensurable` block on the resource, e.g:
  #     newvalue(:latest) { provider.update }
  def update
    raise 'Unimplemented.'
  end

  # The resource thinks we need to destroy it on the system.
  #
  # This is called from the `ensurable` block on the resource, e.g:
  #     newvalue(:absent) { provider.destroy }
  def destroy
    raise 'Unimplemented.'
  end

  # Changes have been made to the resource; apply them.
  #
  # Installing, updating, and uninstalling rustup is handled separately because
  # of the way Puppet logs things.
  def flush
    if resource[:ensure] == :absent
      ensure_absent
    else
      ensure_not_absent
    end
  end

  # Ensure it’s really gone.
  #
  # This is called if `ensure` is `absent` even if `exists? == false`.
  def ensure_absent; end

  # Make sure all the bits and pieces are installed.
  #
  # This is called when `ensure` is not `absent`, i.e. `present` or `latest`. It
  # is called even if `exist? == true`.
  def ensure_not_absent; end

  # Determine if `rustup` has been installed on the system for this user
  def rustup_installed?
    File.file? rustup_path
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

  # Get the entry in /etc/passwd for the specified user.
  def user_entry
    Etc.getpwnam(resource[:user])
  rescue ArgumentError
    nil
  end

  # Check if the specified user actually exists.
  def user_exists?
    !user_entry.nil?
  end

  protected

  # Run a command as the user
  def execute(command, stdin_file: nil, raise_on_failure: true)
    unless user_exists?
      raise Puppet::Error, "User #{resource[:user].inspect} does not exist."
    end

    environment = {
      'PATH' => path_env,
      'RUSTUP_HOME' => resource[:rustup_home],
      'CARGO_HOME' => resource[:cargo_home],
      'RUSTUP_DIST_SERVER' => resource[:dist_server],
    }.compact

    #debug do
      stdin_message = stdin_file ? " and stdin_file #{stdin_file.inspect}" : ''
      warn "!!! Running #{command.inspect} for user " \
      "#{resource[:user].inspect} in #{Dir.pwd} with environment " \
      "#{environment.inspect}#{stdin_message}"
    #end

    if ENV['RUSTUP_TRACE']
      info("as #{resource[:user]}: #{command.join(' ')}")
    end

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

  # Output a debugging message
  def debug(*args)
    Puppet.debug do
      message = if block_given?
                  yield(*args)
                else
                  args.join(' ')
                end
      "#{self.class.resource_type.name}: #{message}"
    end
  end

  # Add logging methods for the other levels
  Puppet::Util::Log.eachlevel do |level|
    if level == :debug
      next
    end

    define_method(level) do |*args, &block|
      message = if block.nil?
                  args.join(' ')
                else
                  block.call(*args)
                end
      Puppet.send_log(level, "#{self.class.resource_type.name}: #{message}")
    end
  end
end
