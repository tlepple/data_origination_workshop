#!/bin/bash

function validate_url(){
    if [[ `wget -S --spider $1  2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
    return 0
  else
    return 1
  fi

}

function get_valid_url(){
if validate_url $url; then
    # Do something when exists
    echo "file exists.  downloading..."
    wget $url
  else
    # Return or print some error
    echo "file: $url -- does not exist"
    exit 
fi
}
