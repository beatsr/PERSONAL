#!/bin/bash
fd -t f -e md -d 5 -p "Journal/\d{4}/\d{2}/\d{2}/" | sort | lua __index.lua
