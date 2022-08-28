# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Puppet::Type.type(:rustup_toolchain) do
  it 'loads' do
    expect(described_class).not_to be_nil
  end

  it 'creates a trivial instance' do
    instance = described_class.new(title: 'u: t')
    expect(instance).not_to be_nil
    expect(instance[:user]).to eq('u')
    expect(instance[:toolchain]).to eq('t')
  end

  it 'fails with a nil title' do
    expect { described_class.new(title: nil) }
      .to raise_error(Puppet::Error, %r{Title or name must be provided})
  end

  it 'fails with an empty title' do
    expect { described_class.new(title: '') }
      .to raise_error(Puppet::Error, %r{Toolchain is required})
  end

  it 'fails with an non-structured title' do
    expect { described_class.new(title: 'a') }
      .to raise_error(Puppet::Error, %r{User is required})
  end

  it 'works with an non-structured title and parameters' do
    instance = described_class.new(
      title: 'a',
      user: 'u',
      toolchain: 't',
    )
    expect(instance).not_to be_nil
    expect(instance[:user]).to eq('u')
    expect(instance[:toolchain]).to eq('t')
  end

  it 'fails with a bad ensure' do
    expect { described_class.new(title: 'u: t', ensure: 'dfasdf') }
      .to raise_error(Puppet::Error, %r{Valid values are present, latest, absent})
  end

  it 'fails with a relative rustup_home' do
    expect { described_class.new(title: 'u: t', rustup_home: '.') }
      .to raise_error(Puppet::Error, %r{Rustup home must be an absolute path})
  end

  it 'works with an absolute rustup_home' do
    expect(described_class.new(title: 'u: t', rustup_home: '/opt/rustup'))
      .not_to be_nil
  end
end
