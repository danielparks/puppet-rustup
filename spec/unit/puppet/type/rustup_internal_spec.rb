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

  it "fails with a blank name" do
    expect { described_class.new(:name => "") }
      .to raise_error(Puppet::Error, /User is required to be a non-empty string/)
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

  it "fails with a relative rustup_home" do
    expect { described_class.new(:name => "user", :rustup_home => "dfasdf") }
      .to raise_error(Puppet::Error, /Rustup home must be an absolute path/)
  end

  it "fails with a nil rustup_home" do
    expect { described_class.new(:name => "user", :rustup_home => nil) }
      .to raise_error(Puppet::Error, /Got nil value for rustup_home/)
  end

  it "works with an absolute rustup_home" do
    expect(described_class.new(:name => "user", :rustup_home => "/opt/rustup"))
      .not_to be_nil
  end

  it "fails with a number installer_source" do
    expect { described_class.new(:name => "user", :installer_source => 3) }
      .to raise_error(Puppet::Error, /Installer source must be a valid URL/)
  end

  it "fails with a nil installer_source" do
    expect { described_class.new(:name => "user", :installer_source => nil) }
      .to raise_error(Puppet::Error, /Got nil value for installer_source/)
  end

  it "fails with a blank installer_source" do
    expect { described_class.new(:name => "user", :installer_source => "") }
      .to raise_error(Puppet::Error, /Installer source must be a valid URL/)
  end

  it "fails with a non-URL installer_source" do
    expect { described_class.new(:name => "user", :installer_source => "s a as") }
      .to raise_error(Puppet::Error, /Installer source must be a valid URL/)
  end

  it "works with a URL installer_source" do
    expect(described_class.new(:name => "user", :installer_source => "http://localhost/foo"))
      .to_not be_nil
  end

  it "has a default for installer_source" do
    expect(described_class.new(:name => "user")[:installer_source])
      .to eq("https://sh.rustup.rs")
  end
end
