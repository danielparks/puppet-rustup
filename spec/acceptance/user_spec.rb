# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'Per-user rustup management' do
  context 'install without toolchain' do
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

    describe file("/home/vagrant/.bashrc") do
      it { should be_file }
      its(:content) { should match %r{^\. "\$HOME/\.cargo/env"$} }
    end

    describe file("/home/vagrant/.profile") do
      it { should be_file }
      its(:content) { should match %r{^\. "\$HOME/\.cargo/env"$} }
    end

    describe command("sudo -iu vagrant echo '$PATH'") do
      its(:stdout) { should match %r{(\A|:)/home/vagrant/\.cargo/bin:} }
      its(:stderr) { should eq "" }
      its(:exit_status) { should eq 0 }
    end

    # FIXME this test will fail if there is any present rustup installation. As
    # long as the tests are run in order (sigh), they should clean themselves
    # up. Unfortunately, there doesn’t seem to be a way to just reset the VM.
    describe command("sudo -iu vagrant cargo install petname") do
      its(:stderr) { should match /error: rustup could not choose a version of cargo to run/ }
      its(:exit_status) { should be > 0 }
    end
  end

  context 'basic install' do
    it do
      idempotent_apply(<<~END)
        package { 'gcc': } # Needed for cargo install
        rustup { 'vagrant': }
        rustup::toolchain { 'vagrant: stable': }
        rustup::default { 'vagrant: stable': }
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

    describe file("/home/vagrant/.bashrc") do
      it { should be_file }
      its(:content) { should match %r{^\. "\$HOME/\.cargo/env"$} }
    end

    describe file("/home/vagrant/.profile") do
      it { should be_file }
      its(:content) { should match %r{^\. "\$HOME/\.cargo/env"$} }
    end

    describe command("sudo -iu vagrant echo '$PATH'") do
      its(:stdout) { should match %r{(\A|:)/home/vagrant/\.cargo/bin:} }
      its(:stderr) { should eq "" }
      its(:exit_status) { should eq 0 }
    end

    describe command("sudo -iu vagrant cargo install --quiet petname") do
      its(:stdout) { should eq "" }
      its(:stderr) { should eq "" }
      its(:exit_status) { should eq 0 }
    end

    describe command("sudo -iu vagrant rustup +stable target list") do
      its(:stdout) {
        should match /-unknown-linux-.* \(installed\)$/
      }
      its(:stderr) { should eq "" }
      its(:exit_status) { should eq 0 }
    end
  end

  context 'basic uninstall' do
    it do
      idempotent_apply(<<~END)
        rustup { 'vagrant':
          ensure => absent,
        }
      END
    end

    describe file("/home/vagrant/.rustup") do
      it { should_not exist }
    end

    describe file("/home/vagrant/.cargo") do
      it { should_not exist }
    end

    describe file("/home/vagrant/.bashrc") do
      it { should be_file }
      its(:content) { should_not match %r{^\. "\$HOME/\.cargo/env"$} }
    end

    describe file("/home/vagrant/.profile") do
      it { should be_file }
      its(:content) { should_not match %r{^\. "\$HOME/\.cargo/env"$} }
    end

    describe command("sudo -iu vagrant echo '$PATH'") do
      its(:stdout) { should_not match %r{(\A|:)/home/vagrant/\.cargo/bin(:|\Z)} }
      its(:stderr) { should eq "" }
      its(:exit_status) { should eq 0 }
    end
  end
end
