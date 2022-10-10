# frozen_string_literal: true

require 'puppet_x/rustup'

# Property classes for rustup
module PuppetX::Rustup::Property
  # A list where the order is not important for changes
  class Set < Puppet::Property
    # Ensure that we compare the entire list.
    def self.array_matching
      :all
    end

    def initialize(*, **)
      @ignore_removed_entries = false
      super
    end

    # Whether or not to consider it a change if there are entries that exist on
    # the system, but aren’t specified in the resource.
    #
    # For example:
    #
    #     directory { 'bar':
    #       files => [ 'a', 'b' ],
    #     }
    #
    # Suppose that `bar` actually has `a`, `b`, and `c` entries on the system.
    # If this method returns `true`, then the above resource will not be
    # considered changed. If it returns `false`, then it will be.
    #
    # This is useful for purge-like functionality.
    #
    # Defaults to false
    attr_accessor :ignore_removed_entries

    # Get the identity of the entry.
    #
    # This is akin to the title of a resource. It should uniquely identify this
    # entry within in the set. If two entries have the same identity, then it
    # is an error.
    def entry_identity(entry)
      entry.hash
    end

    # Does this entry in `should` have the equivalent of `ensure => absent`?
    #
    # This is used to determine if there is a change. If this returns `true` and
    # there is no corresponding entry in `is`, then it will _not_ be considered
    # a change.
    def should_entry_absent?(_entry)
      false
    end

    # Do any normalization required for an entry in `should`.
    #
    # Return the normalized entry or `nil` to skip it.
    def normalize_should_entry(entry)
      entry
    end

    # Do any normalization required for an entry in `is`.
    #
    # Return the normalized entry or `nil` to skip it. If an entry has the
    # equivalent of `ensure => absent`, this should return `nil`.
    def normalize_is_entry(entry)
      entry
    end

    # Run a normalizer on `is` or `should` and make a hash. Takes a block that
    # normalizes an entry.
    #
    # This makes sure that all entries are unique.
    #
    # You should not need to override this.
    def clean_set(entries)
      hash = {}
      entries.each do |entry|
        normalized = yield entry
        if normalized.nil?
          next
        end

        identity = entry_identity(normalized)
        if hash.include? identity
          raise Puppet::Error, "Duplicate entry in set: #{entry.inspect}"
        end
        hash[identity] = normalized
      end
      hash
    end

    # Check if the values are in sync.
    #
    # You should not need to override this.
    def insync?(is)
      clean_should = clean_set(should) { |e| normalize_should_entry(e) }

      begin
        clean_is = clean_set(is) { |e| normalize_is_entry(e) }
      rescue Puppet::Error
        # `clean_is` represents what actually exists, so if there are duplicates
        # it should not fail (though it should be considered a bug). Since we
        # don’t allow `should` to contain duplicates, a duplicate in `is` will
        # always indicate a change.
        return false
      end

      # Remove entries in clean_should from clean_is.
      clean_should.each do |identity, should_entry|
        if clean_is.delete(identity).nil?
          # Found an entry in `should`, but not in `is`. If the entry has the
          # equivalent of `ensure => absent`, then it doesn’t matter.
          unless should_entry_absent? should_entry
            return false
          end
        end
      end

      if ignore_removed_entries
        # Every entry in `should` corresponds to an entry in `is`, so nothing
        # was added.
        true
      else
        # If there is anything left in `clean_is`, then there is a change.
        clean_is.empty?
      end
    end
  end
end
