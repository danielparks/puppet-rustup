# frozen_string_literal: true

require 'spec_helper'
require 'puppet/provider/rustup_internal/shell'

RSpec.describe 'the rustup_internal/shell provider' do
  it 'loads' do
    expect(Puppet::Type.type(:rustup_internal).provide(:shell)).not_to be_nil
  end
end
