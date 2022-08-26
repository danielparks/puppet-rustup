# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Puppet::Type.type(:rustup_internal) do
  it "loads" do
    expect(described_class).not_to be_nil
  end

  it "creates a trivial instance" do
    expect(described_class.new(:name => "user")).to_not be_nil
  end

  it "fails with a nil name" do
    expect { described_class.new(:name => nil) }
      .to raise_error(Puppet::Error, /Title or name must be provided/)
  end

  it "fails with a bad ensure" do
    expect { described_class.new(:name => "user", :ensure => "dfasdf") }
      .to raise_error(Puppet::Error, /Valid values are present, latest, absent/)
  end

  it "has a default for modify_path" do
    expect(described_class.new(:name => "user")[:modify_path])
      .to eq(true)
  end

  it "accepts modify_path" do
    expect(described_class.new(:name => "user", :modify_path => false)[:modify_path])
      .to eq(false)
  end

  it "fails with a blank installer_source" do
    expect { described_class.new(:name => "user", :installer_source => "") }
      .to raise_error(Puppet::Error, /Installer source must not be blank/)
  end

  it "fails with a bad installer_source" do
    expect { described_class.new(:name => "user", :installer_source => "s a as") }
      .to raise_error(Puppet::Error, /Installer source must be a valid URL/)
  end

  it "works with a good installer_source" do
    expect(described_class.new(:name => "user", :installer_source => "http://localhost/foo"))
      .to_not be_nil
  end

  it "has a default for installer_source" do
    expect(described_class.new(:name => "user")[:installer_source])
      .to eq("https://sh.rustup.rs")
  end
end
