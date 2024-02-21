# frozen_string_literal: true

require_relative '../rustup'

# Utility functions for rustup
module PuppetX::Rustup::Util
  # Download a URL into a stream.
  def self.download_into(url, output)
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

  # Make a download available as a `Tempfile` in a block.
  #
  #     download('https://example.com/test.sh', ['test', '.sh']) do |file|
  #       puts "#{file.path} will be deleted after the block ends."
  #     end
  def self.download(url, basename = '')
    file = Tempfile.new(basename, Dir.home)
    begin
      Puppet.debug { "Downloading #{url.inspect} into #{file.path.inspect}" }
      PuppetX::Rustup::Util.download_into(url, file)
      file.flush

      yield(file)
    ensure
      Puppet.debug { "Deleting #{file.path.inspect}" }
      file.close
      file.unlink
    end
  end

  # Remove a line from a file.
  #
  # This does the removal in place to avoid problems with symlinks, hard
  # links, and preserving metadata (like modes and ACLs). This means the
  # removal is not atomic.
  #
  # This only writes to the file if changes are made.
  #
  # line_to_remove is a string that matches the line to remove, not including
  # newlines.
  def self.remove_file_line(path, line_to_remove)
    matcher = Regexp.escape(line_to_remove)
    contents = IO.read(path)
    if contents.gsub!(%r{^#{matcher}(\n|\r\n|\r|\Z)}, '')
      # Substitutions were made
      IO.write(path, contents)
    end
  end

  # Check that input is a non-empty string.
  def self.non_empty_string?(input)
    input.is_a?(String) && !input.empty?
  end

  # Check that input is nil or a non-empty string.
  def self.nil_or_non_empty_string?(input)
    input.nil? || non_empty_string?(input)
  end
end
