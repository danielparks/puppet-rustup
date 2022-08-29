# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'Per-user rustup management' do
  context 'supports installing without toolchain' do
    it do
      idempotent_apply(<<~END)
        rustup { 'vagrant': }
      END
    end

    describe file('/home/vagrant/.rustup') do
      it { is_expected.to be_directory }
      it { is_expected.to be_owned_by 'vagrant' }
    end

    describe file('/home/vagrant/.cargo/bin/rustup') do
      it { is_expected.to be_file }
      it { is_expected.to be_executable }
      it { is_expected.to be_owned_by 'vagrant' }
    end

    describe file('/home/vagrant/.bashrc') do
      it { is_expected.to be_file }
      its(:content) { is_expected.to match %r{^\. "\$HOME/\.cargo/env"$} }
    end

    describe file('/home/vagrant/.profile') do
      it { is_expected.to be_file }
      its(:content) { is_expected.to match %r{^\. "\$HOME/\.cargo/env"$} }
    end

    describe command_as_vagrant("echo '$PATH'") do
      its(:stdout) {
        is_expected.to match %r{(\A|:)/home/vagrant/\.cargo/bin:}
        is_expected.to_not match %r{/opt/rust/cargo/bin}
      }
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end

    describe command_as_vagrant("rustup toolchain list") do
      its(:stdout) { is_expected.to match %r{^no installed toolchains$} }
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end

    describe command_as_vagrant('rm -rf hello-world') do
      its(:exit_status) { is_expected.to eq 0 }
    end

    # FIXME: this test will fail if there is any present rustup installation. As
    # long as the tests are run in order (sigh), they should clean themselves
    # up. Unfortunately, there doesn’t seem to be a way to just reset the VM.
    describe command_as_vagrant('cargo init hello-world --bin --quiet') do
      its(:stderr) { is_expected.to match(%r{error: rustup could not choose a version of cargo to run}) }
      its(:exit_status) { is_expected.to be > 0 }
    end
  end

  context 'supports trivial uninstall for a real user' do
    it do
      idempotent_apply(<<~END)
        rustup { 'vagrant':
          ensure => absent,
        }
      END
    end

    describe file('/home/vagrant/.rustup') do
      it { is_expected.not_to exist }
    end

    describe file('/home/vagrant/.cargo') do
      it { is_expected.not_to exist }
    end

    describe file('/home/vagrant/.bashrc') do
      it { is_expected.to be_file }
      its(:content) { is_expected.not_to match %r{^\. "\$HOME/\.cargo/env"$} }
    end

    describe file('/home/vagrant/.profile') do
      it { is_expected.to be_file }
      its(:content) { is_expected.not_to match %r{^\. "\$HOME/\.cargo/env"$} }
    end

    describe command_as_vagrant("echo '$PATH'") do
      its(:stdout) { is_expected.not_to match %r{(\A|:)/home/vagrant/\.cargo/bin(:|\Z)} }
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end
  end

  context 'supports multi-resource install' do
    it do
      idempotent_apply(<<~END)
        package { 'gcc': } # Needed for cargo install
        rustup { 'vagrant': }
        rustup::toolchain { 'vagrant: stable': }
        rustup::default { 'vagrant: stable': }
      END
    end

    describe file('/home/vagrant/.rustup') do
      it { is_expected.to be_directory }
      it { is_expected.to be_owned_by 'vagrant' }
    end

    describe file('/home/vagrant/.cargo/bin/rustup') do
      it { is_expected.to be_file }
      it { is_expected.to be_executable }
      it { is_expected.to be_owned_by 'vagrant' }
    end

    describe file('/home/vagrant/.bashrc') do
      it { is_expected.to be_file }
      its(:content) { is_expected.to match %r{^\. "\$HOME/\.cargo/env"$} }
    end

    describe file('/home/vagrant/.profile') do
      it { is_expected.to be_file }
      its(:content) { is_expected.to match %r{^\. "\$HOME/\.cargo/env"$} }
    end

    describe command_as_vagrant("echo '$PATH'") do
      its(:stdout) { is_expected.to match %r{(\A|:)/home/vagrant/\.cargo/bin:} }
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end

    describe command_as_vagrant('rm -rf hello-world') do
      its(:exit_status) { is_expected.to eq 0 }
    end

    describe command_as_vagrant('cargo init hello-world --bin --quiet') do
      its(:stdout) { is_expected.to eq '' }
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end

    describe command_as_vagrant('cargo install --quiet --path hello-world') do
      its(:stdout) { is_expected.to eq '' }
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end

    describe file('/home/vagrant/.cargo/bin/hello-world') do
      it { is_expected.to be_executable }
    end

    describe command_as_vagrant('rustup +stable target list') do
      its(:stdout) do
        is_expected.to match(%r{-unknown-linux-.* \(installed\)$})
      end
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end
  end

  context 'supports multi-resource uninstall for a real user' do
    it do
      idempotent_apply(<<~END)
        rustup { 'vagrant':
          ensure => absent,
        }
        rustup::toolchain { 'vagrant: stable':
          ensure => absent,
        }
        rustup::target { 'vagrant: wasm32-unknown-unknown stable':
          ensure => absent,
        }
      END
    end

    describe file('/home/vagrant/.rustup') do
      it { is_expected.not_to exist }
    end

    describe file('/home/vagrant/.cargo') do
      it { is_expected.not_to exist }
    end

    describe file('/home/vagrant/.bashrc') do
      it { is_expected.to be_file }
      its(:content) { is_expected.not_to match %r{^\. "\$HOME/\.cargo/env"$} }
    end

    describe file('/home/vagrant/.profile') do
      it { is_expected.to be_file }
      its(:content) { is_expected.not_to match %r{^\. "\$HOME/\.cargo/env"$} }
    end

    describe command_as_vagrant("echo '$PATH'") do
      its(:stdout) { is_expected.not_to match %r{(\A|:)/home/vagrant/\.cargo/bin(:|\Z)} }
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end
  end

  it 'supports ensure=>absent with non-existant user' do
    expect(user('non_existant_user')).not_to exist

    idempotent_apply(<<~END)
      rustup { 'non_existant_user':
        ensure => absent,
      }
      rustup::toolchain { 'non_existant_user: stable':
        ensure => absent,
      }
      rustup::target { 'non_existant_user: wasm32-unknown-unknown stable':
        ensure => absent,
      }
    END

    expect(user('non_existant_user')).not_to exist
  end

  it 'can remove itself after the user was deleted' do
    expect(user('rustup_test')).not_to exist

    # Generate a separate directory to hold .cargo so we can test that rustup
    # ensure=>absent works when the user is gone but the directory is not.
    idempotent_apply(<<~END)
      user { 'rustup_test':
        ensure     => present,
        managehome => true,
      }

      file { '/rustup_test':
        ensure  => directory,
        owner   => 'rustup_test',
        group   => 'rustup_test',
        mode    => '0755',
        require => User['rustup_test'],
      }

      rustup { 'rustup_test':
        home => '/rustup_test',
      }

      rustup::default { 'rustup_test: stable':
        home => '/rustup_test',
      }
    END

    expect(user('rustup_test')).to exist
    expect(file('/rustup_test/.cargo/bin/rustup')).to exist

    idempotent_apply(<<~END)
      user { 'rustup_test':
        ensure => absent,
      }

      rustup { 'rustup_test':
        ensure => absent,
        home   => '/rustup_test',
      }

      # FIXME currently this runs before rustup. How should it handle the user
      # being going, but the installation being present?
      #rustup::toolchain { 'rustup_test: stable':
      #  ensure => absent,
      #  home   => '/rustup_test',
      #}
    END

    expect(user('rustup_test')).not_to exist
    expect(file('/rustup_test')).to exist
    expect(file('/rustup_test/.cargo')).not_to exist
  end
end
