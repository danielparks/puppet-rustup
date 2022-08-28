# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'Global rustup management' do
  context 'nologin out-of-order install with targets and toolchains' do
    it do
      idempotent_apply(<<~END)
        class { 'rustup::global':
          shell => '/usr/sbin/nologin',
        }

        rustup::global::target { 'wasm32-unknown-unknown stable': }
        rustup::global::target { 'wasm32-unknown-unknown nightly': }
        rustup::global::default { 'stable': }
        rustup::global::toolchain { 'nightly': }
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

    describe command_global_rustup("+stable target list") do
      its(:stdout) {
        should match /^wasm32-unknown-unknown \(installed\)$/
        should match /-unknown-linux-.* \(installed\)$/
      }
      its(:stderr) { should eq "" }
      its(:exit_status) { should eq 0 }
    end

    describe command_global_rustup("+nightly target list") do
      its(:stdout) {
        should match /^wasm32-unknown-unknown \(installed\)$/
        should match /-unknown-linux-.* \(installed\)$/
      }
      its(:stderr) { should eq "" }
      its(:exit_status) { should eq 0 }
    end
  end

  context 'nologin uninstall target' do
    it do
      idempotent_apply(<<~END)
        class { 'rustup::global':
          shell => '/usr/sbin/nologin',
        }

        rustup::global::target { 'wasm32-unknown-unknown stable': }
        rustup::global::target { 'wasm32-unknown-unknown nightly':
          ensure => absent,
        }
        rustup::global::default { 'stable': }
        rustup::global::toolchain { 'nightly': }
      END
    end

    describe command_global_rustup("+stable target list") do
      its(:stdout) {
        should match /^wasm32-unknown-unknown \(installed\)$/
        should match /-unknown-linux-.* \(installed\)$/
      }
      its(:stderr) { should eq "" }
      its(:exit_status) { should eq 0 }
    end

    describe command_global_rustup("+nightly target list") do
      its(:stdout) {
        should match /^wasm32-unknown-unknown$/
        should match /-unknown-linux-.* \(installed\)$/
      }
      its(:stderr) { should eq "" }
      its(:exit_status) { should eq 0 }
    end
  end

  context 'nologin uninstall toolchain' do
    it do
      idempotent_apply(<<~END)
        class { 'rustup::global':
          shell => '/usr/sbin/nologin',
        }

        rustup::global::target { 'wasm32-unknown-unknown stable': }
        rustup::global::target { 'wasm32-unknown-unknown nightly':
          ensure => absent,
        }
        rustup::global::default { 'stable': }
        rustup::global::toolchain { 'nightly':
          ensure => absent,
        }
      END
    end

    describe command_global_rustup("+stable target list") do
      its(:stdout) {
        should match /^wasm32-unknown-unknown \(installed\)$/
        should match /-unknown-linux-.* \(installed\)$/
      }
      its(:stderr) { should eq "" }
      its(:exit_status) { should eq 0 }
    end

    describe command_global_rustup("toolchain list") do
      its(:stdout) {
        should match /^stable-.* \(default\)$/
        should_not match /^nightly-/
      }
      its(:stderr) { should eq "" }
      its(:exit_status) { should eq 0 }
    end
  end

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

  context 'basic uninstall' do
    it do
      idempotent_apply(<<~END)
        class { 'rustup::global':
          ensure => absent,
        }
      END

      expect(user("rustup")).to_not exist
    end

    describe file("/opt/rust") do
      it { should_not exist }
    end

    # FIXME check /etc/bash...
  end
end
