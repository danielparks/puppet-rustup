#!/usr/bin/env ruby

# Fix anchor names in REFERENCE.md.

def anchorify(puppet_path)
  # Valid characters in an anchor fragment are assumed to be the safe characters
  # in an id attribute: “only ASCII letters, digits, '_', and '-'” (see
  # https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/id#sect2)
  puppet_path.tr('^a-zA-Z0-9_-', '-')
end

def munge(path)
  working_path = "#{path}.working"
  File.open(path) do |input|
    File.open(working_path, 'w') do |output|
      section = nil
      input.each do |line|
        if line =~ %r{^### <a name=".*?"></a>`(.*?)`$}
          # Heading for a type, e.g. a class or defined type
          object = Regexp.last_match(1)
          anchor = anchorify(object)
          output.write("### <a name=\"#{anchor}\"></a>`#{object}`\n")
          section = object
        elsif line =~ %r{^##### <a name=".*?"></a>`(.*?)`$}
          # Heading for a parameter
          param = Regexp.last_match(1)
          anchor = anchorify("$#{section}::#{param}")
          output.write("##### <a name=\"#{anchor}\"></a>`#{param}`\n")
        elsif section && line =~ %r{^\* \[`(.*?)`\]\(#.*\)$}
          # * [`name`](#name)
          # within a section
          param = Regexp.last_match(1)
          anchor = anchorify("$#{section}::#{param}")
          output.write("* [`#{param}`](##{anchor})\n")
        elsif section.nil? && line =~ %r{^\* \[`(.*?)`\]\(#.*\)(.*)$}
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
