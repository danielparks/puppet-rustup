# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'Global rustup management' do
  context 'supports basic install with ensure => latest' do
    it do
      # Not idempotent because of ensure => latest.
      apply_manifest(<<~'PUPPET')
        class { 'rustup::global':
          ensure     => latest,
          toolchains => ['stable'],
          targets    => ['default']
        }
      PUPPET

      expect(user('rustup')).to belong_to_group 'rustup'
    end

    describe file('/opt/rust') do
      it { is_expected.to be_directory }
      it { is_expected.to be_owned_by 'rustup' }
    end

    describe file('/opt/rust/cargo/bin/rustup') do
      it { is_expected.to be_file }
      it { is_expected.to be_executable }
      it { is_expected.to be_owned_by 'rustup' }
    end

    describe command_global_rustup('+stable target list') do
      its(:stdout) do
        is_expected.to match(%r{^#{host_target} \(installed\)$})
      end
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end
  end

  # FIXME/BUG this is necessary for the next context block to work
  context 'removes basic install with ensure => absent' do
    it do
      idempotent_apply(<<~'PUPPET')
        class { 'rustup::global':
          ensure => absent,
        }
      PUPPET

      expect(user('rustup')).not_to exist
    end

    describe file('/opt/rust') do
      it { is_expected.not_to exist }
    end
  end

  context 'supports out-of-order targets and toolchains with a false shell' do
    it do
      idempotent_apply(<<~'PUPPET')
        class { 'rustup::global':
          shell            => '/bin/false',
          purge_toolchains => true,
          purge_targets    => true,
        }

        rustup::global::target { 'wasm32-unknown-unknown stable': }
        rustup::global::target { 'wasm32-unknown-unknown nightly': }
        rustup::global::toolchain { 'stable': }
        rustup::global::toolchain { 'nightly': }
      PUPPET

      expect(user('rustup')).to belong_to_group 'rustup'
      expect(user('rustup')).to have_login_shell '/bin/false'
    end

    describe file('/opt/rust') do
      it { is_expected.to be_directory }
      it { is_expected.to be_owned_by 'rustup' }
    end

    describe file('/opt/rust/cargo/bin/rustup') do
      it { is_expected.to be_file }
      it { is_expected.to be_executable }
      it { is_expected.to be_owned_by 'rustup' }
    end

    describe command_global_rustup('+stable target list') do
      its(:stdout) do
        is_expected.to match(%r{^wasm32-unknown-unknown \(installed\)$})
        is_expected.not_to match(%r{^#{host_target} \(installed\)$})
      end
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end

    describe command_global_rustup('+nightly target list') do
      its(:stdout) do
        is_expected.to match(%r{^wasm32-unknown-unknown \(installed\)$})
        is_expected.not_to match(%r{^#{host_target} \(installed\)$})
      end
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end
  end

  context 'supports uninstalling a target with a false shell' do
    it do
      idempotent_apply(<<~'PUPPET')
        class { 'rustup::global':
          shell            => '/bin/false',
          purge_toolchains => true,
          purge_targets    => true,
        }

        rustup::global::target { 'wasm32-unknown-unknown stable': }
        rustup::global::target { 'wasm32-unknown-unknown nightly':
          ensure => absent,
        }
        rustup::global::toolchain { 'stable': }
        rustup::global::toolchain { 'nightly': }
      PUPPET
    end

    describe command_global_rustup('+stable target list') do
      its(:stdout) do
        is_expected.to match(%r{^wasm32-unknown-unknown \(installed\)$})
        is_expected.not_to match(%r{^#{host_target} \(installed\)$})
      end
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end

    describe command_global_rustup('+nightly target list') do
      its(:stdout) do
        is_expected.to match(%r{^wasm32-unknown-unknown$})
        is_expected.not_to match(%r{^#{host_target} \(installed\)$})
      end
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end
  end

  context 'supports uninstalling a toolchain with a false shell' do
    it do
      idempotent_apply(<<~'PUPPET')
        class { 'rustup::global':
          shell            => '/bin/false',
          purge_toolchains => true,
          purge_targets    => true,
        }

        rustup::global::target { 'wasm32-unknown-unknown stable': }
        rustup::global::target { 'wasm32-unknown-unknown nightly':
          ensure => absent,
        }
        rustup::global::toolchain { 'stable': }
        rustup::global::toolchain { 'nightly':
          ensure => absent,
        }
      PUPPET
    end

    describe command_global_rustup('+stable target list') do
      its(:stdout) do
        is_expected.to match(%r{^wasm32-unknown-unknown \(installed\)$})
        is_expected.not_to match(%r{^#{host_target} \(installed\)$})
      end
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end

    describe command_global_rustup('toolchain list') do
      its(:stdout) do
        is_expected.to match(%r{^stable-.* \(.*\bdefault\b.*\)$})
        is_expected.not_to match(%r{^nightly-})
      end
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end
  end

  context 'supports ensure=>absent on multiple resources at once' do
    it do
      idempotent_apply(<<~'PUPPET')
        class { 'rustup::global':
          ensure => absent,
        }
        rustup::global::toolchain { 'nightly':
          ensure => absent,
        }
        rustup::global::target { 'wasm32-unknown-unknown nightly':
          ensure => absent,
        }
      PUPPET

      expect(user('rustup')).not_to exist
    end

    describe file('/opt/rust') do
      it { is_expected.not_to exist }
    end
  end

  context 'supports basic install with no toolchain' do
    it do
      idempotent_apply(<<~'PUPPET')
        include rustup::global
      PUPPET

      expect(user('rustup')).to belong_to_group 'rustup'
    end

    describe file('/opt/rust') do
      it { is_expected.to be_directory }
      it { is_expected.to be_owned_by 'rustup' }
    end

    describe file('/opt/rust/cargo/bin/rustup') do
      it { is_expected.to be_file }
      it { is_expected.to be_executable }
      it { is_expected.to be_owned_by 'rustup' }
    end
  end

  context 'supports basic global uninstall' do
    it do
      idempotent_apply(<<~'PUPPET')
        class { 'rustup::global':
          ensure => absent,
        }
      PUPPET

      expect(user('rustup')).not_to exist
    end

    describe file('/opt/rust') do
      it { is_expected.not_to exist }
    end

    # FIXME: check /etc/bash...
  end
end
