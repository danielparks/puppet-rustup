# Return the default home directory for a user on this OS
#
# @param user
#   The name of the user.
# @return [Stdlib::Absolutepath]
#   The path to the home directory.
function rustup::home(String[1] $user) >> Stdlib::Absolutepath {
    "${lookup('rustup::home', Stdlib::Absolutepath)}${user}"
}
