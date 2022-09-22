#!/usr/bin/env ruby

# Fix anchor names in REFERENCE.md.

def anchorify(puppet_path)
  puppet_path.tr(':$', '__')
end

def munge(path)
  working_path = "${path}.working"
  File.open(path) do |input|
    File.open(working_path, 'w') do |output|
      section = nil
      input.each do |line|
        if line =~ %r{^### <a name=".*?"></a>`(.*?)`$}
          object = Regexp.last_match(1)
          anchor = anchorify(object)
          output.write("### <a name=\"#{anchor}\"></a>`#{object}`\n")
          section = object
        elsif line =~ %r{^##### <a name=".*?"></a>`(.*?)`$}
          param = Regexp.last_match(1)
          anchor = anchorify("#{section}::$#{param}")
          output.write("##### <a name=\"#{anchor}\"></a>`#{param}`\n")
        elsif section and line =~ %r{^\* \[`(.*?)`\]\(#.*\)$}
          # within a section
          # * [`name`](#name)
          param = Regexp.last_match(1)
          anchor = anchorify("#{section}::$#{param}")
          output.write("* [`#{param}`](##{anchor})\n")
        elsif section.nil? and line =~ %r{^\* \[`(.*?)`\]\(#.*\)(.*)$}
          # * [`name`](#name): description
          name = Regexp.last_match(1)
          anchor = anchorify(name)
          suffix = Regexp.last_match(2)
          output.write("* [`#{name}`](##{anchor})#{suffix}\n")
        else
          output.write(line)
        end
      end
    end
  end

  File.rename(working_path, path)
end

munge('REFERENCE.md')
