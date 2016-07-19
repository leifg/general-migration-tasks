#!/bin/bash

bundle install &> /dev/null

echo "Extracting results"
bundle exec ruby extract_results_to_db.rb $@
