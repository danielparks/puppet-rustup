# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Puppet::Type.type(:rustup_internal).provider(:shell) do
  it 'refuses to load instances' do
    expect { described_class.instances }
      .to raise_error(Puppet::Error, %r{Cannot query rustup installations})
  end

  let :type do
    Puppet::Type.type(:rustup_internal)
  end

  it 'succeeds for non-existant user when ensure=>absent' do
    # Assumes that /home/non_existant_user/.cargo/... doesn’t exist.
    resource = type.new(
      title: 'non_existant_user',
      ensure: 'absent',
      provider: :shell,
    )
    expect(resource[:cargo_home]).to eq '/home/non_existant_user/.cargo'
    expect(described_class.new(resource).exists?).to be(false)
  end
end
