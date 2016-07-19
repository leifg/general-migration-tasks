#!/bin/bash

bundle install &> /dev/null

bundle exec ruby create_sqlite.rb $@
