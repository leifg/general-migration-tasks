#!/bin/bash

bundle install &> /dev/null

echo "Import into ${output_db}"
bundle exec ruby create_sqlite.rb $@
