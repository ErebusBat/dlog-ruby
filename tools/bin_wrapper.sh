#!/bin/zsh
################################################################################
### dlog tool wrapper script
################################################################################
# This script sets up the ruby environment that the tool expects and launches
# the tool.  It assumes that if mise isn't installed then ruby is already
# configured on the machine

# Use mise shims, if available
if command -v mise &> /dev/null; then
  eval $(mise activate --shims)
fi

DLOG_RUBY_PATH=$HOME/.local/share/dlog-ruby
if [[ ! -x $DLOG_RUBY_PATH/bin/dlog ]]; then
  echo "*** FATAL: dlog-ruby not found at $DLOG_RUBY_PATH, edit $0"
  exit 1
fi

cd $DLOG_RUBY_PATH
bin/dlog $*
