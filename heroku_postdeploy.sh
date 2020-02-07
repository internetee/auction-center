#!/bin/sh

bundle exec rake db:structure:load
bundle exec rake db:migrate
bundle exec rake db:seed
