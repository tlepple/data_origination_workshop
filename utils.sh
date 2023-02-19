#!/bin/bash

function validate_url(){
    if [[ `wget -S --spider $1  2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
    return 0
  else
    return 1
  fi

}

function get_valid_url(){
if validate_url $1; then
    # Download when exists
    echo "file exists.  downloading..."
    wget $1 --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 --tries=4 -P ~/data_origination_workshop/downloads

  else
    # print error and exit the install
     echo "file: $1 -- does not exist.  Aborting the install."
     exit 1
fi
}

