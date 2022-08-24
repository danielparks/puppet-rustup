# frozen_string_literal: true

require 'spec_helper'
require 'puppet/type/rustup'

RSpec.describe 'the rustup type' do
  it 'loads' do
    expect(Puppet::Type.type(:rustup)).not_to be_nil
  end
end
