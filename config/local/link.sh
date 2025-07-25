#!/usr/bin/env zsh
setopt nullglob
local_cfg_path=$(dirname "$(realpath "$0")")
echo "Removing symlinks in $local_cfg_path:"
cd $local_cfg_path
for f in *.rb; do
  if [[ -L $f ]]; then
    rm -v $f
  fi
done

echo ""
echo "Linking files"
for f in ~/.config/dlog/*.rb; do
  ln -s $f
done
ls -l *.rb
