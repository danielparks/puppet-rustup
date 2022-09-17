# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'Per-user rustup management' do
  context 'supports installing without toolchain' do
    it do
      idempotent_apply(<<~'END')
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
      its(:stdout) do
        is_expected.to match %r{(\A|:)/home/vagrant/\.cargo/bin:}
        is_expected.not_to match %r{/opt/rust/cargo/bin}
      end
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end

    describe command_as_vagrant('rustup toolchain list') do
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
      its(:stderr) do
        is_expected.to match(
          %r{error: rustup could not choose a version of cargo to run},
        )
      end
      its(:exit_status) { is_expected.to be > 0 }
    end
  end

  context 'supports trivial uninstall for a real user' do
    it do
      idempotent_apply(<<~'END')
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
      its(:stdout) do
        is_expected.not_to match %r{(\A|:)/home/vagrant/\.cargo/bin(:|\Z)}
      end
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end
  end

  context 'supports multi-resource install' do
    it do
      # FIXME: need a way to specify that the default target should be installed
      idempotent_apply(<<~'END')
        package { 'gcc': } # Needed for cargo install
        rustup { 'vagrant': }
        rustup::toolchain { 'vagrant: stable': }
        rustup::target { 'vagrant: x86_64-unknown-linux-gnu stable': }
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
      idempotent_apply(<<~'END')
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
      its(:stdout) do
        is_expected.not_to match %r{(\A|:)/home/vagrant/\.cargo/bin(:|\Z)}
      end
      its(:stderr) { is_expected.to eq '' }
      its(:exit_status) { is_expected.to eq 0 }
    end
  end

  it 'supports ensure=>absent with non-existant user' do
    expect(user('non_existant_user')).not_to exist

    idempotent_apply(<<~'END')
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

    apply_manifest(<<~'END')
      user { 'rustup_test':
        ensure     => present,
        managehome => true,
      }

      file { '/home/rustup_test/.bashrc':
        ensure  => file,
        owner   => 'rustup_test',
        group   => 'rustup_test',
        mode    => '0644',
        content => "# .bashrc\n",
        require => User['rustup_test'],
        before  => Rustup['rustup_test'],
      }

      rustup { 'rustup_test': }
      rustup::toolchain { 'rustup_test: stable': }
    END

    expect(user('rustup_test')).to exist
    expect(file('/home/rustup_test/.cargo/bin/rustup')).to exist
    expect(file('/home/rustup_test/.bashrc').content)
      .to eq %(# .bashrc\n. "$HOME/.cargo/env"\n)

    apply_manifest(<<~'END')
      user { 'rustup_test':
        ensure => absent,
      }
    END

    expect(user('rustup_test')).not_to exist
    expect(file('/home/rustup_test/.cargo/bin/rustup')).to exist
    expect(file('/home/rustup_test/.bashrc').content)
      .to eq %(# .bashrc\n. "$HOME/.cargo/env"\n)

    idempotent_apply(<<~'END')
      rustup { 'rustup_test':
        ensure => absent,
      }

      rustup::toolchain { 'rustup_test: stable':
        ensure => absent,
      }
    END

    expect(user('rustup_test')).not_to exist
    expect(file('/home/rustup_test')).to exist
    expect(file('/home/rustup_test/.cargo')).not_to exist
    expect(file('/home/rustup_test/.bashrc').content).to eq %(# .bashrc\n)
  end

  it 'can remove itself after the user was deleted (with custom cargo_home)' do
    expect(user('rustup_test')).not_to exist

    apply_manifest(<<~'END')
      user { 'rustup_test':
        ensure     => present,
        managehome => true,
      }

      file {
        default:
          owner   => 'rustup_test',
          group   => 'rustup_test',
          mode    => '0644',
          require => User['rustup_test'],
          before  => Rustup['rustup_test'],
        ;
        '/home/rustup_test/.bashrc':
          ensure  => file,
          content => "# .bashrc\n",
        ;
        ['/home/rustup_test/a', '/home/rustup_test/a/b']:
          ensure => directory,
        ;
      }

      rustup { 'rustup_test':
        cargo_home => '/home/rustup_test/a/b/.cargo',
      }

      rustup::toolchain { 'rustup_test: stable': }
    END

    expect(user('rustup_test')).to exist
    expect(file('/home/rustup_test/a/b/.cargo/bin/rustup')).to exist
    expect(file('/home/rustup_test/.bashrc').content)
      .to eq %(# .bashrc\n. "/home/rustup_test/a/b/.cargo/env"\n)

    apply_manifest(<<~'END')
      user { 'rustup_test':
        ensure => absent,
      }
    END

    expect(user('rustup_test')).not_to exist
    expect(file('/home/rustup_test/a/b/.cargo/bin/rustup')).to exist
    expect(file('/home/rustup_test/.bashrc').content)
      .to eq %(# .bashrc\n. "/home/rustup_test/a/b/.cargo/env"\n)

    idempotent_apply(<<~'END')
      rustup { 'rustup_test':
        ensure     => absent,
        cargo_home => '/home/rustup_test/a/b/.cargo',
      }

      rustup::toolchain { 'rustup_test: stable':
        ensure => absent,
      }
    END

    expect(user('rustup_test')).not_to exist
    expect(file('/home/rustup_test')).to exist
    expect(file('/home/rustup_test/a/b/.cargo')).not_to exist
    expect(file('/home/rustup_test/.bashrc').content).to eq %(# .bashrc\n)
  end
end
