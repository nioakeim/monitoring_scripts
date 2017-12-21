#!/bin/bash
# Simple check proxy script compatible with nagios and icinga monitoring systems using curl
# Author: nioakeim
# Version: 1.1
# Release Date: 21/12/2017

default_timeout=10
default_port_http=49809
default_port_https=49816

usage () {
  cat << EOH
  Usage:
      $0 -u|--url -p|--proxy -l|--port -t|--timeout -e|--expect -h|--help

    -u|--url      :    The url you want to request from the proxy server
    -p|--proxy    :    The proxy server ip address or fqdn
    -l|--port     :    The proxy server port
    -t|--timeout  :    The total request timeout
    -m|--connect  :    The connect time timeout. Different from -t
    -e|--expect   :    The expected server reponse on the request
    -d|--debug    :    Enable debuging output
    -h|--help     :    Print this help message
EOH
}

while getopts "u:p:l:t:c:e:dh" opt; do
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
            timeout="--max-time "${OPTARG}
            ;;
        c|--connect)
            ctimeout="--connect-timeout "${OPTARG}
            ;;
        e|--expect)
            expect=${OPTARG}
            ;;
        d|--debug)
            debug=1
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

# Check for necessary arguments for the script to work
if [[ -z $url || -z $proxy ]]; then
  echo "UNKNOWN: Not enough arguments"
  usage
  exit 3
fi

request_curl=$(curl -x $proxy:$port $timeout $ctimeout -o /dev/null --silent --head --write-out '%{http_code}|%{time_total}' $url)
ret=$?

server_response=$(echo $request_curl | awk -F"|" '{ print $1 }')
response_time=$(echo $request_curl | awk -F"|" '{ print $2 }')

if [[ ! -z $debug ]]; then
  echo "DEBUG: Expected response is: $expect"
  echo "DEBUG: Curl Request got $request_curl"
  echo "DEBUG: Server response $server_response"
  echo "DEBUG: Response time $response_time"
fi

# Inspect server response_time for failures like 503 and 000
if [[ $server_response -eq "503" || $server_response -eq "000" ]]; then
  echo "CRITICAL: Proxy responded with $server_response. Service Unavailable"
  exit 2
fi

# Inspect expect
if [[ ! -z $expect && $server_response -ne $expect ]]; then
  echo "WARNING: Proxy is reachable but server response is $server_response instead of $expect"
  exit 1
fi

# Inspect Exit code
if [[ $ret -eq 0 ]]; then
  echo "OK: No problems. Server response was $server_response in $response_time sec | 'response_time_time'="$response_time"s"
  exit 0
elif [[ $ret -eq 7 ]]; then
  echo "CRITICAL: Proxy Server is unreachable"
  exit 2
elif [[ $ret -eq 28 ]]; then
  echo "CRITICAL: Proxy connection timed out at $timeout sec"
  exit 2
else
  echo "CRITICAL: curl exited with $ret error code. Please check man curl for exit code $ret"
  exit 2
fi
