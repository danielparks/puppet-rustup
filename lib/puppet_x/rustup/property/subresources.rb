# frozen_string_literal: true

require_relative 'set'

# Property classes for rustup
module PuppetX::Rustup::Property
  # A list of subresources
  #
  # This is a list of hashes that correspond to sub-resources. It expects each
  # hash to have, at the least, a 'title' entry that identifies it uniquely
  # within this list of resources, and an 'ensure' entry that contains either
  # 'absent' or something else that will be interpreted as not-absent.
  class Subresources < Set
    # Get the identity of the entry.
    #
    # This is akin to the title of a resource. It should uniquely identify this
    # entry within in the set. If two entries have the same identity, then it
    # is an error.
    def entry_identity(entry)
      h = entry.to_h.reject { |k| k == 'ensure' }
      if entry['normalized_name']
        h[:name] = entry['normalized_name']
      end
      Puppet.notice("entry_identity(#{entry.inspect}) == #{h.inspect}.hash == #{h.hash.inspect}")
      h.hash
    end

    # Does this entry in `should` have the equivalent of `ensure => absent`?
    #
    # This is used to determine if there is a change. If this returns `true` and
    # there is no corresponding entry in `is`, then it will _not_ be considered
    # a change.
    def should_entry_absent?(entry)
      entry['ensure'] == 'absent'
    end

    # Do any normalization required for an entry in `should`.
    #
    # Return the normalized entry or `nil` to skip it.
    #
    # This clones entry and passes it to `normalize_should_entry!`. Unless you
    # need to return `nil`, you should override that function.
    def normalize_should_entry(entry)
      cloned = entry.clone
      normalize_should_entry!(cloned)
      cloned
    end

    # Do any normalization required for an entry in `is`.
    #
    # Return the normalized entry or `nil` to skip it. If an entry has the
    # equivalent of `ensure => absent`, this should return `nil`.
    #
    # This clones entry and passes it to `normalize_is_entry!`. Unless you need
    # to return `nil`, you should override that function.
    def normalize_is_entry(entry)
      cloned = entry.clone
      normalize_is_entry!(cloned)
      cloned
    end

    # Do any normalization required for an entry in `should`.
    #
    # This should modify the parameter.
    def normalize_should_entry!(_entry); end

    # Do any normalization required for an entry in `is`.
    #
    # This should modify the parameter.
    def normalize_is_entry!(_entry); end

    # Raise a friendly error if a hash entry is not in valid_set.
    def validate_in(entry, attr, valid_set)
      unless valid_set.any? entry[attr]
        raise Puppet::Error, 'Expected %{name} Hash entry %{attr} to be one ' \
          'of %{valid}, got %{value}' % {
            name: name,
            attr: attr.inspect,
            valid: valid_set.inspect,
            value: entry[attr].inspect,
          }
      end
    end

    # Raise a friendly error if a hash entry is not a non-empty string.
    def validate_non_empty_string(entry, attr)
      unless PuppetX::Rustup::Util.non_empty_string? entry[attr]
        raise Puppet::Error, 'Expected %{name} Hash entry %{attr} to be a ' \
          'non-empty string, got %{value}' % {
            name: name,
            attr: attr.inspect,
            value: entry[attr].inspect,
          }
      end
    end

    # Raise a friendly error if a hash entry is not nil or a non-empty string.
    def validate_nil_or_non_empty_string(entry, attr)
      unless PuppetX::Rustup::Util.nil_or_non_empty_string? entry[attr]
        raise Puppet::Error, 'Expected %{name} Hash entry %{attr} to be nil ' \
          'or a non-empty string, got %{value}' % {
            name: name,
            attr: attr.inspect,
            value: entry[attr].inspect,
          }
      end
    end

    # Format existing values for display.
    #
    # Often we use a subresource class to handle subresource collections in the
    # provider, which interferes with the display of changed values.
    #
    # @param values [Array] the values to format as a string
    # @return [String] a pretty printing string
    # rubocop:disable Naming/PredicateName
    def is_to_s(values)
      if values.is_a? PuppetX::Rustup::Provider::Collection
        values = values.system
      end
      super(values.map { |subresource| subresource.to_h })
    end
    # rubocop:enable Naming/PredicateName

    # Format new values for display.
    #
    # Often we use a subresource class to handle subresource collections in the
    # provider, which interferes with the display of changed values.
    #
    # @param values [Array] the values to format as a string
    # @return [String] a pretty printing string
    def should_to_s(values)
      super(values.map { |subresource| subresource.to_h })
    end

    # Check if entries with the same identity are different.
    def entry_changed?(is_entry, should_entry)
      Puppet.notice("is(#{is_entry.inspect}) != shoud(#{should_entry.inspect}): #{is_entry != should_entry}")
      is_entry != should_entry
    end
  end
end
