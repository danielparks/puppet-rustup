# @summary Profile for toolchain installation
#
# `default` is a keyword in Puppet, so it must always be wrapped in quotes.
type Rustup::Profile = Enum[minimal, 'default', complete]
