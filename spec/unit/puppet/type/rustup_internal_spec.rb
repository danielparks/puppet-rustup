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
end
