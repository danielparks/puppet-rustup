# frozen_string_literal: true

require 'spec_helper'
require 'puppet_x/rustup/property/set'

RSpec.describe PuppetX::Rustup::Property::Set do
  before(:each) do
    # IDEK copied from puppet/spec/unit/property/list_spec.rb
    described_class.initvars
  end

  let :resource do
    # rubocop:disable RSpec/VerifiedDoubles
    double('resource', :[]= => nil, :property => nil)
    # rubocop:enable RSpec/VerifiedDoubles
  end

  let :property do
    described_class.new(resource:)
  end

  [true, false].each do |value|
    context "common (ignore_removed_entries = #{value})" do
      before(:each) do
        property.ignore_removed_entries = value
      end

      it 'considers equal hashes the same' do
        property.should = [{ 'a' => 'A' }]
        expect(property.insync?([{ 'a' => 'A' }])).to eq true
      end

      it 'considers unequal hashes a change' do
        property.should = [{ 'a' => 'A', 'b' => 'B' }]
        expect(property.insync?([{ 'a' => 'A' }])).to eq false
      end

      it 'considers same entries to be the same' do
        property.should = ['a', 'b']
        expect(property.insync?(['a', 'b'])).to eq true
      end

      it 'considers duplicate new entries to be an error' do
        property.should = ['a', 'b', 'b']
        expect { property.insync?(['a', 'b']) }
          .to raise_error(Puppet::Error, 'Duplicate entry in set: "b"')
      end

      it 'considers duplicate old entries to be a change' do
        property.should = ['a', 'b']
        expect(property).to receive(:warn)
          .with('Error in existing : Duplicate entry in set: "b"')
        expect(property.insync?(['a', 'b', 'b'])).to eq false
      end
    end
  end

  context 'ignore_removed_entries = false' do
    before(:each) do
      property.ignore_removed_entries = false
    end

    it 'considers fewer entries to be a change' do
      property.should = ['a', 'b']
      expect(property.insync?(['a', 'b', 'c'])).to eq false
    end
  end

  context 'ignore_removed_entries = true' do
    before(:each) do
      property.ignore_removed_entries = true
    end

    it 'considers fewer entries to be the same' do
      property.should = ['a', 'b']
      expect(property.insync?(['a', 'b', 'c'])).to eq true
    end
  end
end
