# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'Global rustup management' do
  context 'basic install' do
    it do
      idempotent_apply(<<~END)
        include rustup
      END

      describe file("/opt/rust") do
        it { should be_directory }
        it { should be_owned_by "rustup" }
      end
      expect(user("rustup")).to belong_to_group "rustup"
    end
  end
end
