# frozen_string_literal: true

require 'spec_helper'

describe 'rustup::toolchain' do
  let(:pre_condition) { 'rustup { "user": }' }
  let(:title) { 'user: toolchain' }
  let(:params) do
    {}
  end

  it { is_expected.to compile }
end
