#!/bin/sh
# Fun fact: this replaced an 87 line PHP script :)
find $* \
  \( \( -not -perm 0755 \) -and -type d -exec chmod 0755 {} \; \) \
  -or \
  \( \( -not -perm 0644 \) -and -type f -exec chmod 0644 {} \; \)
