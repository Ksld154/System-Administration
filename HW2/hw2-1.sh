#! /bin/sh
echo "`ls -lAR | grep ^- | sort -k 5 -n -r | head -n 5 | awk '{print NR ": " $5 " " $9}'``ls -lAR | grep ^d | wc -l | awk '{print "\nDir num: "$1}'``ls -lAR | grep ^- | wc -l | awk '{print "\nFile num: "$1}'``ls -lAR | grep ^- | awk '{total+=$5}; END {print "\nTotal: "total}'`"
