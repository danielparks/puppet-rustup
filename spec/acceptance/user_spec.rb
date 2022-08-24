# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'Per-user rustup management' do
  context 'basic install' do
    it do
      idempotent_apply(<<~END)
        rustup { 'vagrant': }
      END
    end

    describe file("/home/vagrant/.rustup") do
      it { should be_directory }
      it { should be_owned_by "vagrant" }
    end

    describe file("/home/vagrant/.cargo/bin/rustup") do
      it { should be_file }
      it { should be_executable }
      it { should be_owned_by "vagrant" }
    end
  end
end
