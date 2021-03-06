#!/bin/sh
# SMART <SHORTCUT>
MD5SUM='<MD5SUM>'
SUBMODULE='<SUBMODULE>'
OBJPATH='<OBJPATH>'
# EOH

# determine .git directory
set -euf -o pipefail
export ORIG0="$0"
scriptdir=$(dirname "$0")
scriptbase=$(basename "$0")
gitdir=$(readlink -f "$scriptdir")
while [ x"$gitdir" != x"/" ]
do
  [ -d "$gitdir"/.git ] && break
  gitdir=$(dirname "$gitdir")
done
if [ x"$gitdir" = x"/" ] ; then
  echo "Unable to find gitdir"
  exit 1
fi

#
if [ -x "$gitdir/../$SUBMODULE/$OBJPATH" ] ; then
  exec "$gitdir/../$SUBMODULE/$OBJPATH" "$@"
fi

if [ ! -f "$gitdir/.gitmodules" ] ; then
  echo "$0: not installed properly" 1>&2
  exit 2
fi

subpath=$(grep '[ \t]*path[ \t]*=[ \t]*' "$gitdir/.gitmodules" \
	| sed -e 's!^[ \t]*path[ \t]*=[ \t]!!' \
	| grep -E '(^'"$SUBMODULE"'$|/'"$SUBMODULE"')')
if [ -z "$subpath" ] ; then
  echo "$SUBMODULE: Missing submodule path!" 1>&2
  exit 3
fi

if [ ! -x "$gitdir/$subpath/$OBJPATH" ] ; then
  # Check if we need to refresh things...
  if [ ! -e $gitdir/$subpath/.git ]  ; then
    # Checkout without submodules...
    ( cd "$gitdir" ; git submodule update --init --recursive $subpath ) 1>&2
  else
    # Maybe we need to update it...
    ( cd "$gitdir" ; git submodule update $subpath ) 1>&2
  fi
  if [ ! -x "$gitdir/$subpath/$OBJPATH" ] ; then
    echo "$OBJPATH: not found" 1>&2
    exit 4
  fi
fi
exec "$gitdir/$subpath/$OBJPATH" "$@"

