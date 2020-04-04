#!/bin/bash

set -eux

which ruby
which tidy
rubocop -a || true
ruby html.rb
find docs -name '*.html' -type f -print -exec tidy -mq '{}' \;