# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Puppet::Type.type(:rustup_internal).provider(:shell) do
  it "should refuse to load instances" do
    expect { described_class.instances }
      .to raise_error(RuntimeError, /Cannot query rustup installations/)
  end

  let :resource do
    Puppet::Type.type(:rustup_internal).new(:title => "root", :provider => :shell)
  end

  let :provider do
    described_class.new(resource)
  end

  it "has correct rustup_home" do
    expect(provider.rustup_home).to eq(File.expand_path("~root/.rustup"))
  end
end
