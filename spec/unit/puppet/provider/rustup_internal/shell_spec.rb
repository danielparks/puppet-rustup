# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Puppet::Type.type(:rustup_internal).provider(:shell) do
  it 'refuses to load instances' do
    expect { described_class.instances }
      .to raise_error(Puppet::Error, %r{Cannot query rustup installations})
  end

  let :type do
    Puppet::Type.type(:rustup_internal)
  end

  it 'has correct rustup_home' do
    resource = type.new(title: 'root', provider: :shell)
    expect(described_class.new(resource).rustup_home)
      .to eq(File.expand_path('~root/.rustup'))
  end

  it 'fails for invalid user' do
    resource = type.new(title: 'invalid-user', provider: :shell)
    expect { described_class.new(resource).rustup_home }
      .to raise_error(ArgumentError, %r{can't find user for invalid-user})
  end
end
