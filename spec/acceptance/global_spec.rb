# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'Global rustup management' do
  context 'basic install' do
    it do
      idempotent_apply(<<~END)
        include rustup::global
      END

      expect(user("rustup")).to belong_to_group "rustup"
    end

    describe file("/opt/rust") do
      it { should be_directory }
      it { should be_owned_by "rustup" }
    end

    describe file("/opt/rust/cargo/bin/rustup") do
      it { should be_file }
      it { should be_executable }
      it { should be_owned_by "rustup" }
    end
  end

  context 'nologin install' do
    it do
      idempotent_apply(<<~END)
        class { 'rustup::global':
          shell => '/usr/sbin/nologin',
        }
      END

      expect(user("rustup")).to belong_to_group "rustup"
      expect(user("rustup")).to have_login_shell "/usr/sbin/nologin"
    end

    describe file("/opt/rust") do
      it { should be_directory }
      it { should be_owned_by "rustup" }
    end

    describe file("/opt/rust/cargo/bin/rustup") do
      it { should be_file }
      it { should be_executable }
      it { should be_owned_by "rustup" }
    end
  end
end
