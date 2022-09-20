# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Puppet::Type.type(:rustup_internal) do
  it 'loads' do
    expect(described_class).not_to be_nil
  end

  describe 'a trivial instance' do
    let :resource do
      described_class.new(title: 'user')
    end

    it 'has the correct parameters' do
      expect(resource).not_to be_nil
      expect(resource[:modify_path]).to eq true
      expect(resource[:home]).to eq '/home/user'
      expect(resource[:rustup_home]).to eq '/home/user/.rustup'
      expect(resource[:cargo_home]).to eq '/home/user/.cargo'
      expect(resource[:installer_source]).to eq 'https://sh.rustup.rs'
    end
  end

  it 'fails with a nil title' do
    expect { described_class.new(title: nil) }
      .to raise_error(Puppet::Error, %r{Title or name must be provided})
  end

  it 'fails with a blank title' do
    expect { described_class.new(title: '') }
      .to raise_error(Puppet::Error,
        %r{User is required to be a non-empty string})
  end

  it 'fails with a bad ensure' do
    expect { described_class.new(title: 'user', ensure: 'dfasdf') }
      .to raise_error(Puppet::Error,
        %r{Valid values are present, latest, absent})
  end

  it 'accepts modify_path' do
    expect(described_class.new(title: 'user', modify_path: false)[:modify_path])
      .to eq(false)
  end

  it 'fails with a relative rustup_home' do
    expect { described_class.new(title: 'user', rustup_home: 'dfasdf') }
      .to raise_error(Puppet::Error, %r{Rustup home must be an absolute path})
  end

  it 'fails with a nil rustup_home' do
    expect { described_class.new(title: 'user', rustup_home: nil) }
      .to raise_error(Puppet::Error, %r{Got nil value for rustup_home})
  end

  it 'works with an absolute rustup_home' do
    expect(described_class.new(title: 'user', rustup_home: '/opt/rustup'))
      .not_to be_nil
  end

  context 'dist_server' do
    it 'fails with a number' do
      expect { described_class.new(title: 'user', dist_server: 3) }
        .to raise_error(Puppet::Error, %r{dist_server must be a valid URL})
    end

    it 'fails with a blank' do
      expect { described_class.new(title: 'user', dist_server: '') }
        .to raise_error(Puppet::Error, %r{dist_server must be a valid URL})
    end

    it 'fails with a non-URL' do
      expect { described_class.new(title: 'user', dist_server: 's a as') }
        .to raise_error(Puppet::Error, %r{dist_server must be a valid URL})
    end

    it 'works with a URL' do
      expect(described_class.new(title: 'user', dist_server: 'http://test'))
        .not_to be_nil
    end
  end

  context 'installer_source' do
    it 'fails with a blank' do
      expect { described_class.new(title: 'user', installer_source: '') }
        .to raise_error(Puppet::Error, %r{Installer source must be a valid URL})
    end

    it 'fails with a non-URL' do
      expect { described_class.new(title: 'user', installer_source: 's a as') }
        .to raise_error(Puppet::Error, %r{Installer source must be a valid URL})
    end

    it 'works with a URL' do
      expect(described_class.new(title: 'user', installer_source: 'http://foo'))
        .not_to be_nil
    end
  end
end
