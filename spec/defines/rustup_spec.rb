# frozen_string_literal: true

require 'spec_helper'

describe 'rustup' do
  describe 'trivial resource' do
    let(:title) { 'user' }
    let(:params) do
      {}
    end

    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }

        it { is_expected.to compile }
      end
    end
  end

  describe 'resource with targets and toolchains' do
    let(:title) { 'user' }
    let(:params) do
      {
        toolchains: ['stable', 'nightly'],
        targets: [
          'wasm32-unknown-unknown',
          'x86_64-apple-darwin nightly',
          'x86_64-apple-darwin stable',
        ],
      }
    end

    it { is_expected.to compile }
  end
end
