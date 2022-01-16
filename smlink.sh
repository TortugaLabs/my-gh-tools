#!/bin/sh
set -euf -o pipefail
O0="$0"
if [ -n "${ORIG0:-}" ] ; then
  O0="${ORIG0}"
fi

if [ $# -eq 0 ] ; then
  echo "Usage: $O0 {target} {link-name}"
  exit 1
fi

target="$1"
if [ $# -gt 1 ] ; then
  cd "$(dirname "$2")"
  link_name=$(basename "$2")
else
  link_name=$(basename "$1")
fi

