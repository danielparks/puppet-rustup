# @summary Set the correct ordering of defined types
#
# This class is used internally; you do not need to include it yourself.
class rustup::ordering {
  # Run rustup::exec after installations are installed...
  Rustup_internal <| ensure != absent |>
    -> Rustup::Exec <| |>
  # ...and before installations are removed.
    -> Rustup_internal <| ensure == absent |>

  # Targets go after installations, toolchains, and defaults are installed...
  Rustup_internal <| ensure != absent |>
    -> Rustup_toolchain <| ensure != absent |>
    -> Rustup::Default <| |>
    -> Rustup::Target <| |>
  # ...and before toolchains and installations are removed.
    -> Rustup_toolchain <| ensure == absent |>
    -> Rustup_internal <| ensure == absent |>
}
