# frozen_string_literal: true

require_relative '../provider'

# A toolchain subresource
class PuppetX::Rustup::Provider::Toolchain
  class << self
    def property(name)
      attr_accessor(name)
      @properties ||= []
      @properties << name
    end

    def parameter(name)
      attr_accessor(name)
      @parameters ||= []
      @parameters << name
    end

    def properties
      @properties || []
    end

    def parameters
      @parameters || []
    end
  end

  property :name
  property :ensure
  parameter :profile
  parameter :normalized_name

  def initialize(**kwargs)
    kwargs.each do |key, value|
      self[key] = value
    end
  end

  def to_h
    h = {}
    self.class.properties.each do |key|
      h[key] = send(key)
    end
    # FIXME: parameters
    h
  end

  # Validate members against the property and parameter list rather than just
  # trying to `send()` to avoid being able to call any function ending with
  # "=" just by passing the right hash to the constructor.
  def valid_member?(key)
    key = key.to_sym
    self.class.properties.include?(key) || self.class.parameters.include?(key)
  end

  def validate_member(key)
    unless valid_member?(key)
      raise NameError, "invalid member #{key.inspect}"
    end
  end

  def [](key)
    validate_member(key)
    send(key)
  end

  def []=(key, value)
    validate_member(key)
    send("#{key}=", value)
  end

  def self.from_system(name)
    toolchain = new(name: name, ensure: 'present')
    toolchain.normalized_name = name
    toolchain
  end
end
