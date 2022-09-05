# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../lib/puppet_x/rustup/util'

RSpec.describe PuppetX::Rustup::Util do
  context 'remove_file_line' do
    # Run all tests in a temporary directory
    around(:each) do |example|
      Dir.mktmpdir(example.description.gsub(%r{[^a-z0-9_.-]+}i, '_')) do |path|
        Dir.chdir(path) do
          example.run
        end
      end
    end

    it 'does not change a file without the line' do
      IO.write('input.txt', "line 1\nline 2\n")
      old_inode = File.stat('input.txt').ino
      described_class.remove_file_line('input.txt', 'REMOVE')
      expect(File.stat('input.txt').ino).to eq old_inode
      expect(Dir.children('.')).to eq ['input.txt']
    end

    it 'removes a line from a file in place' do
      IO.write('input.txt', "line 1\nREMOVE\nline 3")
      old_inode = File.stat('input.txt').ino
      described_class.remove_file_line('input.txt', 'REMOVE')
      expect(File.stat('input.txt').ino).to eq old_inode
      expect(IO.read('input.txt')).to eq "line 1\nline 3"
      expect(Dir.children('.')).to eq ['input.txt']
    end

    it 'preserves permissions when changing file' do
      IO.write('input.txt', "line 1\nREMOVE\nline 3")
      File.chmod(0o651, 'input.txt')
      old_mode = '%o' % File.stat('input.txt').mode
      described_class.remove_file_line('input.txt', 'REMOVE')
      expect('%o' % File.stat('input.txt').mode).to eq old_mode
      expect(IO.read('input.txt')).to eq "line 1\nline 3"
      expect(Dir.children('.')).to eq ['input.txt']
    end

    it 'removes all lines from a file' do
      IO.write('input.txt', "REMOVE\nREMOVE\nREMOVE")
      described_class.remove_file_line('input.txt', 'REMOVE')
      expect(IO.read('input.txt')).to eq ''
      expect(Dir.children('.')).to eq ['input.txt']
    end

    it 'removes multiple lines from a file' do
      IO.write('input.txt', "line 1\nREMOVE\nline 3\nREMOVE")
      described_class.remove_file_line('input.txt', 'REMOVE')
      expect(IO.read('input.txt')).to eq "line 1\nline 3\n"
      expect(Dir.children('.')).to eq ['input.txt']
    end

    it 'does not remove similar lines from a file' do
      IO.write('input.txt', "line 1\nREMOVE \nline 3\nREMOVE")
      described_class.remove_file_line('input.txt', 'REMOVE')
      expect(IO.read('input.txt')).to eq "line 1\nREMOVE \nline 3\n"
      expect(Dir.children('.')).to eq ['input.txt']
    end

    it 'does not treat line to remove as a regular expression' do
      IO.write('input.txt', "line 1\nREMO.E\nline 3\nREMOVE")
      described_class.remove_file_line('input.txt', 'REMO.E')
      expect(IO.read('input.txt')).to eq "line 1\nline 3\nREMOVE"
      expect(Dir.children('.')).to eq ['input.txt']
    end

    it 'handles mixed newlines' do
      IO.write('input.txt', "line 1\r\nREMOVE\rline 3\nREMOVE\r\n\rline 4")
      described_class.remove_file_line('input.txt', 'REMOVE')
      expect(IO.read('input.txt')).to eq "line 1\r\nline 3\n\rline 4"
      expect(Dir.children('.')).to eq ['input.txt']
    end
  end
end
