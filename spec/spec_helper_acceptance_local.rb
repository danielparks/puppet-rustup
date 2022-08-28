# frozen_string_literal: true

def command_global_rustup(params)
  command("sudo -u rustup " +
    "RUSTUP_HOME=/opt/rust/rustup CARGO_HOME=/opt/rust/cargo " +
    "/opt/rust/cargo/bin/rustup #{params}")
end
