#!/bin/bash 
# install as cron job

# quote2note writes files in public cache directory
LOG_DIR="/home/ubuntu/quote2note/log"
sudo chmod go+w $LOG_DIR
LOG="$LOG_DIR/clearcache.log"
printf "q2n: clearing public cache of .mid .wav .mp3 files\n" >>$LOG
date >>$LOG
ls $Q2N_DIR  >>$LOG
rm -f $Q2N_DIR/*.mid >>$LOG
rm -f $Q2N_DIR/*.wav >>$LOG
rm -f $Q2N_DIR/*.mp3 >>$LOG
sudo chmod go-w $LOG_DIR
