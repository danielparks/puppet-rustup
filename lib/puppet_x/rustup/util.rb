# frozen_string_literal: true

require 'puppet_x'

# Support module for rustup
module PuppetX::Rustup
  # Utility functions for rustup
  module Util
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
  end
end
