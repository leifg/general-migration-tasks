#!/bin/bash

printenv
echo $HOME
ruby create-sqlite.rb ../../csv-files/*.csv
