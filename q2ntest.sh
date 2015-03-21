#!/bin/bash
# repeatedly runs q2ntest.js at random intervals up to MAXSLEEP seconds
MAXSLEEP=300
while true; do
    node q2ntest.js
    sleep $(( $RANDOM % $MAXSLEEP ))
done
