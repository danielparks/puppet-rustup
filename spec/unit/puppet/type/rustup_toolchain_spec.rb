# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Puppet::Type.type(:rustup_toolchain) do
  it 'loads' do
    expect(described_class).not_to be_nil
  end

  describe 'a trivial instance' do
    let :resource do
      described_class.new(title: 'u: t')
    end

    it 'has the correct parameters' do
      expect(resource).not_to be_nil
      expect(resource[:user]).to eq 'u'
      expect(resource[:toolchain]).to eq 't'
      expect(resource[:rustup_home]).to eq '/home/u/.rustup'
      expect(resource[:cargo_home]).to eq '/home/u/.cargo'
    end
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

  describe 'an instance with a non-structured title' do
    let :resource do
      described_class.new(
        title: 'a',
        user: 'u',
        toolchain: 't',
      )
    end

    it 'has the correct parameters' do
      expect(resource).not_to be_nil
      expect(resource[:user]).to eq 'u'
      expect(resource[:toolchain]).to eq 't'
      expect(resource[:rustup_home]).to eq '/home/u/.rustup'
      expect(resource[:cargo_home]).to eq '/home/u/.cargo'
    end
  end

  it 'fails with a bad ensure' do
    expect { described_class.new(title: 'u: t', ensure: 'dfasdf') }
      .to raise_error(Puppet::Error,
        %r{Valid values are present, latest, absent})
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
