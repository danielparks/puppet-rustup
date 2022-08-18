#!/bin/bash

set -e

if [ $(id -u) != 0 ] ; then
  exec sudo -u root -p "Password for %p on %H: " /bin/bash "$0" "$@"
fi

cd "$( dirname "${BASH_SOURCE[0]}" )"

export DEBIAN_FRONTEND=noninteractive
if ! command -v puppet &>/dev/null ; then
  apt-get update
  apt-get install -y puppet
fi

puppet module uninstall --force dp-rustup || true
puppet module install ../pkg/dp-rustup-*.tar.gz

echo Running Puppet
puppet apply vagrant.pp
