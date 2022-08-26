# frozen_string_literal: true

require 'spec_helper'
require 'puppet/type/rustup_internal'

RSpec.describe Puppet::Type.type(:rustup_internal) do
  it "should load" do
    expect(described_class).not_to be_nil
  end

  it "should be able to create a trivial instance" do
    expect(described_class.new(:name => "user")).to_not be_nil
  end

  it "should fail with a nil name" do
    expect { described_class.new(:name => nil) }
      .to raise_error(Puppet::Error, /Title or name must be provided/)
  end

  it "should fail with a bad ensure" do
    expect { described_class.new(:name => "user", :ensure => "dfasdf") }
      .to raise_error(Puppet::Error, /Valid values are present, latest, absent/)
  end

  it "should have default modify_path" do
    expect(described_class.new(:name => "user")[:modify_path])
      .to eq(true)
  end

  it "should accept modify_path" do
    expect(described_class.new(:name => "user", :modify_path => false)[:modify_path])
      .to eq(false)
  end

  it "should fail with a blank installer_source" do
    expect { described_class.new(:name => "user", :installer_source => "") }
      .to raise_error(Puppet::Error, /Installer source must not be blank/)
  end

  it "should fail with a bad installer_source" do
    expect { described_class.new(:name => "user", :installer_source => "s a as") }
      .to raise_error(Puppet::Error, /Installer source must be a valid URL/)
  end

  it "should work with a good installer_source" do
    expect(described_class.new(:name => "user", :installer_source => "http://localhost/foo"))
      .to_not be_nil
  end

  it "should have default installer_source" do
    expect(described_class.new(:name => "user")[:installer_source])
      .to eq("https://sh.rustup.rs")
  end
end
