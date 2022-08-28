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

      expect(user('rustup')).to belong_to_group 'rustup'
      expect(user('rustup')).to have_login_shell '/usr/sbin/nologin'
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
        is_expected.to match(%r{-unknown-linux-.* \(installed\)$})
      end
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end

    describe command_global_rustup('+nightly target list') do
      its(:stdout) do
        is_expected.to match(%r{^wasm32-unknown-unknown \(installed\)$})
        is_expected.to match(%r{-unknown-linux-.* \(installed\)$})
      end
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
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

    describe command_global_rustup('+stable target list') do
      its(:stdout) do
        is_expected.to match(%r{^wasm32-unknown-unknown \(installed\)$})
        is_expected.to match(%r{-unknown-linux-.* \(installed\)$})
      end
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end

    describe command_global_rustup('+nightly target list') do
      its(:stdout) do
        is_expected.to match(%r{^wasm32-unknown-unknown$})
        is_expected.to match(%r{-unknown-linux-.* \(installed\)$})
      end
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
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

    describe command_global_rustup('+stable target list') do
      its(:stdout) do
        is_expected.to match(%r{^wasm32-unknown-unknown \(installed\)$})
        is_expected.to match(%r{-unknown-linux-.* \(installed\)$})
      end
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end

    describe command_global_rustup('toolchain list') do
      its(:stdout) do
        is_expected.to match(%r{^stable-.* \(default\)$})
        is_expected.not_to match(%r{^nightly-})
      end
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end
  end

  context 'multi-resource uninstall' do
    it do
      idempotent_apply(<<~END)
        class { 'rustup::global':
          ensure => absent,
        }
        rustup::global::toolchain { 'stable':
          ensure => absent,
        }
        rustup::global::toolchain { 'nightly':
          ensure => absent,
        }
        rustup::global::target { 'wasm32-unknown-unknown stable':
          ensure => absent,
        }
        rustup::global::target { 'wasm32-unknown-unknown nightly':
          ensure => absent,
        }
      END

      expect(user('rustup')).not_to exist
    end

    describe file('/opt/rust') do
      it { is_expected.not_to exist }
    end
  end

  context 'basic install' do
    it do
      idempotent_apply(<<~END)
        include rustup::global
      END

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

  context 'basic uninstall' do
    it do
      idempotent_apply(<<~END)
        class { 'rustup::global':
          ensure => absent,
        }
      END

      expect(user('rustup')).not_to exist
    end

    describe file('/opt/rust') do
      it { is_expected.not_to exist }
    end

    # FIXME: check /etc/bash...
  end
end
