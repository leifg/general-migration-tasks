#!/bin/sh

bundle install
bundle exec ruby create_sqlite.rb csv-files/*
