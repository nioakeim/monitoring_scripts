#!/bin/bash
# Simple check proxy script compatible with nagios and icinga monitoring systems using curl
# Author: nioakeim
# Version: 1.0
# Release Date: 20/12/2017

default_timeout=10
default_expect=200
default_port_http=3128
default_port_https=3128

usage () {
  echo "$0 -u|--url -p|--proxy -l|--port -t|--timeout -e|--expect -h|--help"
}

while getopts "u:p:l:t:e:h" opt; do
    case $opt in
        u|--url)
            url=${OPTARG}
            ;;
        p|--proxy)
            proxy=${OPTARG}
            ;;
        l|--port)
            port=${OPTARG}
            ;;
        t|--timeout)
            timeout=${OPTARG}
            ;;
        e|--expect)
            expect=${OPTARG}
            ;;
        h|--help)
            usage
	    exit 0
            ;;
    esac
done


if [[ $url == 'https:'* ]];then
  if [[ -z $port ]]; then port=$default_port_https ; fi
elif [[ $url == 'http:'* ]]; then
  if [[ -z $port ]]; then port=$default_port_http  ; fi
fi

if [[ -z $expect  ]]; then  expect=$default_expect  ; fi
if [[ -z $timeout ]]; then timeout=$default_timeout ; fi

# Check for necessary arguments for the script to work
if [[ -z $url || -z $proxy || -z $timeout ]]; then
  echo "UNKNOWN: Not enough arguments"
  usage
  exit 3
fi

time1=$(date +%s%3N)
request=$(curl -x $proxy:$port -o /dev/null --silent --head --write-out '%{http_code}\n' $url)
ret=$?
time2=$(date +%s%3N)
response=$(echo "scale=2 ; ($time2-$time1)/1000" | bc)

if [[ $request -ne $expect ]]; then
  echo "WARNING: Proxy is reachable but server response is $request instead of $expect"
  exit 1
fi

if [[ $ret -eq 0 ]]; then
  echo "OK: No problems occurred | 'response_time'=$(printf '%.2f\n' $response)s"
  exit 0
elif [[ $ret -eq 7 ]]; then
  echo "CRITICAL: Proxy Server is unreachable"
  exit 2
else
  echo "CRITICAL: curl exited with $ret error code. Please check man curl for exit code $ret"
  exit 2
fi
