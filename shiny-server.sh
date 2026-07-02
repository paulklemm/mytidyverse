#!/bin/sh

# Make sure the directory for individual app logs exists
mkdir -p /var/log/shiny-server
chown shiny:shiny /var/log/shiny-server

if [ "$APPLICATION_LOGS_TO_STDOUT" = "false" ];
then
    exec shiny-server 2>&1
else
    # push the "real" application logs to stdout with xtail
    xtail /var/log/shiny-server/ &

    # keep shiny-server as PID 1 so it receives signals from docker stop
    exec shiny-server 2>&1
fi