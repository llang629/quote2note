#!/bin/bash 
# install as cron job

# quote2note caches files in public directory
LOG = /home/ubuntu/quote2note/log/passenger.80.log
printf "q2n: clearing public cache of .mid .wav .mp3 files " >>$LOG
date >>$LOG
ls $Q2N_DIR  >>$LOG
rm $Q2N_DIR/*.mid >>$LOG
rm $Q2N_DIR/*.wav >>$LOG
rm $Q2N_DIR/*.mp3 >>$LOG
