#!/usr/bin/env bash

#
#
# This script will manage starting/stopping a Rails application with Thin.
#
# Set the variables below to customize the script and tell it 
# where your Rails application is located.
#
# If you set THIN_NUM_SERVERS greater than 1, Thin will start servers listening in LISTEN_PORT+N for each server.
# For example, if the LISTEN_PORT is 5000 and the THIN_NUM_SERVERS is 3, Thin will start the application and
# listen on ports 5000, 5001, and 5002.
# 
#

APP_NAME="myrailsapp"
RAILS_APP_DIR="/path/to/rails/app"
PID_LOCATION="/tmp"
PID_NAME="myrailsapp"
RAILS_ENV="production"
LISTEN_PORT=5000
THIN_NUM_SERVERS=3

THIN_OPTS="-e $RAILS_ENV -p $LISTEN_PORT -P $PID_LOCATION/$PID_NAME.pid -s $THIN_NUM_SERVERS"
THIN="/usr/bin/thin"

usage() {
  echo "usage: $0 {start|stop|restart|status}."
}

set -e

get_pids() {
 PID_FILES=`find $PID_LOCATION/ -name "$PID_NAME.*.pid"`
}

#
# Goes through each of the PID files and kills the processes.
# Returns true if it killed THIN_NUM_SERVERS processes.
#
stop_thin_instances() {
  NUM_SERVERS=0
  get_pids
  for f in $PID_FILES; do
    if ps -p `cat $f` &> /dev/null; then
      kill -9 `cat $f`
      rm -f $f
      let NUM_SERVERS=$NUM_SERVERS+1
    fi
  done
  [ $NUM_SERVERS -eq $THIN_NUM_SERVERS ]
}

#
# Goes through each of the PID files and sees if the processes are running.
#
is_running() {
  NUM_SERVERS=0
  get_pids
  for f in $PID_FILES; do
    if ps -p `cat $f` &> /dev/null; then
      let NUM_SERVERS=$NUM_SERVERS+1
    fi
  done
  [ $NUM_SERVERS -gt 0 ]
}

case $1 in
start)
  echo -n "Starting $APP_NAME..."
  if is_running; then
    echo "failed (already running)."
  else
    cd $RAILS_APP_DIR
    $THIN $THIN_OPTS start &> /dev/null
    echo "done."
  fi
  ;;
stop)
  echo -n "Stopping $APP_NAME..."
  if is_running; then
    if stop_thin_instances; then
      echo "done."
    else
      echo "failed!"
    fi
  else
    echo "failed (not running)."
  fi
  ;;
status)
  if is_running; then
    echo "$APP_NAME is running."
  else
    echo "$APP_NAME is not running."
  fi
  ;;
restart)
  $0 stop
  $0 start
  ;;
*)
  usage
  ;;
esac