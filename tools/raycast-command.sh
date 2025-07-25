#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Daily Log
# @raycast.mode silent

# Optional parameters:
# @raycast.icon ✏️
# @raycast.argument1 { "type": "text", "placeholder": "Entry Text" }
# @raycast.packageName ErebusBat/dlog-ruby

# Documentation:
# @raycast.description Append Daily Log Entry
# @raycast.author ErebusBat

# Be sure that your environment is setup for any tools you may need/want to use
export PATH=$HOME/bin:$PATH

# This should point to the location of the tools/bin_wrapper.sh script
~/bin/dlog $*
