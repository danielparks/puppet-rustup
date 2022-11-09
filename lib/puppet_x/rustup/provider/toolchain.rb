# frozen_string_literal: true

require_relative '../provider'

# A toolchain subresource
module PuppetX::Rustup::Provider
  Toolchain = Struct.new(:name, :ensure, keyword_init: true) do
    attr_accessor :normalized_name

    def self.from_system(name)
      toolchain = new(name: name, ensure: 'present')
      toolchain.normalized_name = name
      toolchain
    end
  end
end
