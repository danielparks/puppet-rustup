# frozen_string_literal: true

require 'spec_helper'
require 'puppet/type/rustup_internal'

RSpec.describe 'the rustup_internal type' do
  it 'loads' do
    expect(Puppet::Type.type(:rustup_internal)).not_to be_nil
  end
end
