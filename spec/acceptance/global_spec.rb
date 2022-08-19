# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'Global rustup management' do
  context 'basic install' do
    it do
      idempotent_apply(<<~END)
        include rustup
      END

      expect(user("rustup")).to belong_to_group "rustup"
    end
    describe file("/opt/rust") do
      it { should be_directory }
      it { should be_owned_by "rustup" }
    end
  end
end
