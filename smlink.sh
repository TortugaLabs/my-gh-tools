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

link_hdr=$(readlink  -f $(dirname "$0")/smlink-hdr.sh)

target="$1"
if [ $# -gt 1 ] ; then
  if [ -d "$2" ] ; then
    cd "$(dirname "$2")"
    link_name=$(basename "$1" .sh)
  else
    cd "$(dirname "$2")"
    link_name=$(basename "$2")
  fi
else
  link_name=$(basename "$1" .sh)
fi

if [ -e "$link_name" ] ; then
  echo "$link_name: already exists!" 1>&2
  exit 2
fi
if [ ! -e "$target" ] ; then
  echo "$target: not found"
  exit 3
fi

#
# Find subdir
#
subdir=$(readlink -f "$target")
objpath=$(basename "$subdir")
subdir=$(dirname "$subdir")
while [ x"$subdir" != x"/" ]
do
  [ -e "$subdir"/.git ] && break
  objpath="$(basename "$subdir")/$objpath"
  subdir=$(dirname "$subdir")
done
if [ x"$subdir" = x"/" ] ; then
  echo "Unable to find submodule dir"
  exit 1
fi

md5num=$(md5sum "$link_hdr"|cut -f1 -d' ')
submodule=$(basename "$subdir")

#
# Find gitdir
#
# determine .git directory
gitdir=$(readlink -f ".")
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
# Make sure the subpath exists
#
subpath=$(grep '[ \t]*path[ \t]*=[ \t]*' "$gitdir/.gitmodules" \
	| sed -e 's!^[ \t]*path[ \t]*=[ \t]!!' \
	| grep -E '(^'"$submodule"'$|/'"$submodule"')')
if [ -z "$subpath" ] ; then
  echo "$SUBMODULE: Missing submodule path!" 1>&2
  exit 3
fi
if [ ! -f "$subpath/$objpath" ] ; then
  echo "$objpath: not found in $subpath" 1>&2
  exit 4
fi



sed \
	-e "s|<SHORTCUT>|SHORTCUT|" \
	-e "s|<MD5SUM>|$md5num|" \
	-e "s|<SUBMODULE>|$submodule|" \
	-e "s|<OBJPATH>|$objpath|" \
	< "$link_hdr" >"$link_name"
chmod a+x "$link_name"

echo "subdir=$subdir"
echo "objpath=$objpath"
echo "link_hdr=$link_hdr"
echo "md5num=$md5num"
echo "submodule=$submodule"
echo "link_name=$link_name"
echo "target=$target"
exit
