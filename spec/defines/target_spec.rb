# frozen_string_literal: true

require 'spec_helper'

describe 'rustup::target' do
  let(:pre_condition) { 'rustup { "user": }' }
  let(:title) { 'user: target toolchain' }
  let(:params) do
    {}
  end

  it { is_expected.to compile }
end
