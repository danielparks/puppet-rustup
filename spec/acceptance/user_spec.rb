# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'Per-user rustup management' do
  context 'install without toolchain' do
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

    describe command("sudo -iu vagrant echo '$PATH'") do
      its(:stdout) { is_expected.to match %r{(\A|:)/home/vagrant/\.cargo/bin:} }
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end

    # FIXME: this test will fail if there is any present rustup installation. As
    # long as the tests are run in order (sigh), they should clean themselves
    # up. Unfortunately, there doesn’t seem to be a way to just reset the VM.
    describe command('sudo -iu vagrant cargo install petname') do
      its(:stderr) { is_expected.to match(%r{error: rustup could not choose a version of cargo to run}) }
      its(:exit_status) { is_expected.to be > 0 }
    end
  end

  context 'trivial uninstall' do
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

    describe command("sudo -iu vagrant echo '$PATH'") do
      its(:stdout) { is_expected.not_to match %r{(\A|:)/home/vagrant/\.cargo/bin(:|\Z)} }
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end
  end

  context 'multi-resource install' do
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

    describe command("sudo -iu vagrant echo '$PATH'") do
      its(:stdout) { is_expected.to match %r{(\A|:)/home/vagrant/\.cargo/bin:} }
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end

    describe command('sudo -iu vagrant cargo install --quiet petname') do
      its(:stdout) { is_expected.to eq '' }
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end

    describe command('sudo -iu vagrant rustup +stable target list') do
      its(:stdout) do
        is_expected.to match(%r{-unknown-linux-.* \(installed\)$})
      end
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end
  end

  context 'multi-resource uninstall' do
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

    describe command("sudo -iu vagrant echo '$PATH'") do
      its(:stdout) { is_expected.not_to match %r{(\A|:)/home/vagrant/\.cargo/bin(:|\Z)} }
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end
  end
end
