#!/bin/bash

set -e

export UTIL_TRACE=1
source util.sh

usage () {
  echo "Usage: $0 COMMAND"
  echo ""
  echo "COMMAND may be one of:"
  echo "  init     initialize test set up"
  echo "  update   reinstall module"
  echo "  run      run tests"
  echo "  destroy  destroy virtual machines"
}

init () {
  # FIXME sometimes we just want to ensure that things are set up, and not
  # actually recreate everything
  rake litmus:tear_down
  rake 'litmus:provision_list[default]'

  bolt_task_run puppet_agent::install collection=puppet6 version=latest
  bolt_task_run provision::fix_secure_path path=/opt/puppetlabs/bin
  rake litmus:install_module
}

update () {
  rake litmus:reinstall_module
}

run () {
  rake litmus:acceptance:parallel
}

destroy () {
  rake litmus:tear_down
}

case "$1" in
  init|update|run|destroy) "$@" ;;
  --help) usage ;;
  *) usage >&2 ; exit 1 ;;
esac