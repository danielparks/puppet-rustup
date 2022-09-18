# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Puppet::Type.type(:rustup_internal).provider(:default) do
  it 'refuses to load instances' do
    expect { described_class.instances }
      .to raise_error(Puppet::Error, %r{Cannot query rustup installations})
  end

  let :type do
    Puppet::Type.type(:rustup_internal)
  end

  it 'succeeds for non-existant user when ensure=>absent' do
    # Assumes that /home/non_existant_user/.cargo/... doesn’t exist.
    resource = type.new(
      title: 'non_existant_user',
      ensure: 'absent',
      provider: :default,
    )
    expect(resource[:cargo_home]).to eq '/home/non_existant_user/.cargo'
    expect(described_class.new(resource).exists?).to be(false)
  end

  context 'deals with toolchains' do
    let :provider do
      resource = type.new(
        title: 'root',
        provider: :default,
      )
      provider = described_class.new(resource)
      allow(provider).to receive(:load_default_target) \
        .and_return('x86_64-apple-darwin')
      provider
    end

    it 'parses default toolchain correctly' do
      expect(provider.parse_default_target)
        .to eq(['', 'x86_64', 'apple-darwin', nil])
    end

    context 'correctly normalizes toolchain' do
      it '"stable"' do
        expect(provider.normalize_toolchain_name('stable'))
          .to eq('stable-x86_64-apple-darwin')
      end

      it '"custom-toolchain"' do
        expect(provider.normalize_toolchain_name('custom-toolchain'))
          .to eq('custom-toolchain-x86_64-apple-darwin')
      end

      it '"custom-toolchain-mscv"' do
        expect(provider.normalize_toolchain_name('custom-toolchain-msvc'))
          .to eq('custom-toolchain-x86_64-apple-darwin-msvc')
      end

      it '"custom-toolchain-pc-windows"' do
        expect(provider.normalize_toolchain_name('custom-toolchain-pc-windows'))
          .to eq('custom-toolchain-x86_64-pc-windows')
      end
    end
  end
end
