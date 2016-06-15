#!/bin/bash

asset_path=$1
output_db=$2
csv_files=(${asset_path}/*.csv)

export DB_FILE_NAME=$output_db

bundle install &> /dev/null

echo "Import into ${output_db}"
bundle exec ruby create-sqlite.rb ${csv_files[@]}
