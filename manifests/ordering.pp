# @summary Set the correct ordering of defined types
#
# This class is used internally; you do not need to include it yourself.
class rustup::ordering {
  # Generally exec requires an installation...
  Rustup_internal <| |> -> Rustup::Exec <| |>
  # ...except when the installation is being deleted. In that case, the exec
  # probably doesn’t need to run. Making the exec dependent on `rustup` being
  # installed can help:
  #
  #     onlyif => "sh -c 'command -v rustup &>/dev/null' && ...",

  # Targets go after installations, toolchains, and defaults are installed...
  Rustup_internal <| |>
  -> Rustup_toolchain <| ensure != absent |>
  -> Rustup::Default <| |>
  -> Rustup::Target <| |>
  # ...and before toolchains are removed.
  -> Rustup_toolchain <| ensure == absent |>
}
