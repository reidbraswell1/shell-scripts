#!/bin/bash
#
# Custom shell script to create an image file backup to a usb 
# drive already mounted with a partition large enough to hold all
# of the images.
#
# Global Variables
TIMESTAMP=`date +"%d%b%Y"`
PARTS=(1 2 3 4 5 6 8 12 13 7)
DRV="/dev/sda"
BKP_DRV="sda"
DESC="backup"
DASH="-"
BS=4096
DIR="/mnt"
PRODUCTION=true;
SLEEP_TIME=5s;

# Start time of the entire backup
start=$(date +"%s")

# Function to compute the elapsed time given the start time
ELAPSED_TIME() {
    local start=$1
    local total=$2
    end=$(date +"%s")
    elapsed_seconds=$((end - start))
    hours=$((elapsed_seconds / 3600))
    minutes=$(( (elapsed_seconds % 3600) / 60 ))
    seconds=$((elapsed_seconds % 60))
    if $total; then
        echo -e "*** Total Elapsed time: $hours hours, $minutes minutes, $seconds seconds ***\n"
    else
        echo -e "*** Elapsed time: $hours hours, $minutes minutes, $seconds seconds ***\n"
    fi
}

for PART in "${PARTS[@]}"; do
    p_start=$(date +"%s")
    echo "Backing up PARTITION $PART"
    if $PRODUCTION; then
        dd if=$DRV$PART of=$DIR/$BKP_DRV$PART$DASH$DESC$DASH$TIMESTAMP
    else
        sleep $SLEEP_TIME
    fi
    ELAPSED_TIME $p_start false
done
ELAPSED_TIME $start true
exit