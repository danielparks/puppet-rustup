# frozen_string_literal: true

require 'spec_helper'

describe 'rustup::home' do
  it { is_expected.to run.with_params(nil).and_raise_error(StandardError) }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      if os.start_with? 'darwin-'
        it { is_expected.to run.with_params('foo').and_return('/Users/foo') }
      else
        it { is_expected.to run.with_params('foo').and_return('/home/foo') }
      end
    end
  end
end
