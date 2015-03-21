#!/bin/bash
# repeatedly runs q2ntest.js at random intervals up to MAXSLEEP seconds

MAXSLEEP=300

while true; do
    TZ='America/Los_Angeles' date
    node q2ntest.js #or nodejs q2ntest.js depending on environment
    sleep $(( $RANDOM % $MAXSLEEP ))
done
