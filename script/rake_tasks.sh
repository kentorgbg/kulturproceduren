#!/bin/bash

. /etc/profile

RAILS_DIR=$1
RAILS_ENV=$2

if [ -z $RAILS_DIR ]; then
   RAILS_DIR=/srv/rails/kp-dev
fi

if [ -z $RAILS_ENV ]; then
   RAILS_ENV=development
fi


if [ ! -d $RAILS_DIR/lib/tasks ]; then
   echo "No rails-dir $RAILS_DIR"
   exit -1
fi

cd $RAILS_DIR

echo -n "Begin rake tasks KP, RAILS_ENV=$RAILS_ENV at "
date

echo "-- kp:notify_occasion_reminder"
/home/kp-production/.rbenv/shims/bundle exec rake RAILS_ENV=$RAILS_ENV kp:notify_occasion_reminder

echo "-- kp:notify_ticket_release"
/home/kp-production/.rbenv/shims/bundle exec rake RAILS_ENV=$RAILS_ENV kp:notify_ticket_release

echo "-- kp:remind_answer_form"
/home/kp-production/.rbenv/shims/bundle exec rake RAILS_ENV=$RAILS_ENV kp:remind_answer_form

echo "-- kp:send_answer_forms"
/home/kp-production/.rbenv/shims/bundle exec rake RAILS_ENV=$RAILS_ENV kp:send_answer_forms

echo "-- kp:update_tickets"
/home/kp-production/.rbenv/shims/bundle exec rake RAILS_ENV=$RAILS_ENV kp:update_tickets

echo "-- kp:send_bus_bookings"
/home/kp-production/.rbenv/shims/bundle exec rake RAILS_ENV=$RAILS_ENV kp:send_bus_bookings

echo -n "all tasks done at "
date
