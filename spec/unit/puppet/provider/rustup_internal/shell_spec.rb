# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Puppet::Type.type(:rustup_internal).provide(:shell) do
  it 'loads' do
    expect(described_class).not_to be_nil
  end
end
