# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Puppet::Type.type(:rustup_toolchain).provider(:exec) do
  it "should refuse to load instances" do
    expect { described_class.instances }
      .to raise_error(RuntimeError, /Cannot query rustup installations/)
  end

  let :resource do
    Puppet::Type.type(:rustup_toolchain).new(
      :title => "root: toolchain",
      :provider => :exec,
    )
  end

  let :provider do
    described_class.new(resource)
  end

  it "has correct rustup_home" do
    expect(provider.rustup_home).to eq(File.expand_path("~root/.rustup"))
  end

  context "produces good toolchain matchers" do
    it 'for "stable"' do
      expect(provider.make_toolchain_matcher("stable"))
        .to eq(/^stable-.+-.+-.+(?: \(default\))?$/)
    end

    it 'for "custom-toolchain"' do
      expect(provider.make_toolchain_matcher("custom-toolchain"))
        .to eq(/^custom\-toolchain-.+-.+-.+(?: \(default\))?$/)
    end

    it 'for "custom-toolchain-mscv"' do
      expect(provider.make_toolchain_matcher("custom-toolchain-msvc"))
        .to eq(/^custom\-toolchain-.+-.+-msvc(?: \(default\))?$/)
    end

    it 'for "custom-toolchain-pc-windows"' do
      expect(provider.make_toolchain_matcher("custom-toolchain-pc-windows"))
        .to eq(/^custom\-toolchain-.+-pc\-windows-.+(?: \(default\))?$/)
    end
  end
end
