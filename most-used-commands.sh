#!/bin/bash

# Just some fun

cat ~/.bash_history | awk '{ print $1 }' | sort | uniq -c | sort -nr | head -5
