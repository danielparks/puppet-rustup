# frozen_string_literal: true

require 'spec_helper'
require 'puppet_x/rustup/property/subresources'

RSpec.describe PuppetX::Rustup::Property::Subresources do
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
    described_class.new(resource: resource)
  end

  def example(title, ensure_: 'present')
    { 'ensure' => ensure_, 'title' => title }
  end

  [true, false].each do |value|
    context "common (ignore_removed_entries = #{value})" do
      before(:each) do
        property.ignore_removed_entries = value
      end

      it 'considers identical hashes the same' do
        property.should = [example('a')]
        expect(property.insync?([example('a')])).to eq true
      end

      it 'considers changing ensure to latest a change' do
        property.should = [example('a', ensure_: 'latest')]
        expect(property.insync?([example('a', ensure_: 'present')])).to eq false
      end

      it 'fails on duplicate new hashes' do
        property.should = [example('a'), example('a')]
        expect { property.insync?([example('a')]) }
          .to raise_error(Puppet::Error, %r{\ADuplicate entry in set: })
      end

      it 'considers duplicate old entries to be a change' do
        property.should = [example('a')]
        expect(property.insync?([example('a'), example('a')])).to eq false
      end

      it 'considers new absent entries to be the same' do
        property.should = [
          example('a'), example('b'), example('c', ensure_: 'absent')
        ]
        is = [
          example('a'), example('b')
        ]
        expect(property.insync?(is)).to eq true
      end

      it 'considers new present entries to be a change' do
        property.should = [
          example('a'), example('b'), example('c', ensure_: 'present')
        ]
        is = [
          example('a'), example('b')
        ]
        expect(property.insync?(is)).to eq false
      end
    end
  end

  context 'ignore_removed_entries = false' do
    before(:each) do
      property.ignore_removed_entries = false
    end

    it 'considers fewer entries to be a change' do
      property.should = [
        example('a'), example('b')
      ]
      is = [
        example('a'), example('b'), example('c')
      ]
      expect(property.insync?(is)).to eq false
    end
  end

  context 'ignore_removed_entries = true' do
    before(:each) do
      property.ignore_removed_entries = true
    end

    it 'considers fewer entries to be the same' do
      property.should = [
        example('a'), example('b')
      ]
      is = [
        example('a'), example('b'), example('c')
      ]
      expect(property.insync?(is)).to eq true
    end
  end
end
