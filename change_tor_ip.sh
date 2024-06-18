#!/bin/bash

PIDFILE="/tmp/tor_ip_changer.pid"

# Function to display the table header
display_header() {
    printf "%-20s | %-20s | %-20s\n" "Timestamp" "TOR Status" "Current IP"
    printf "%s\n" "----------------------------------------------------------"
}

# Function to display the table row with data
display_row() {
    printf "%-20s | %-20s | %-20s\n" "$1" "$2" "$3"
}

# Function to change TOR IP and display status
change_tor_ip() {
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$timestamp - Changing TOR IP..."

    # Send signal to TOR to change IP
    echo "SIGNAL NEWNYM" | nc 127.0.0.1 9051
    sleep 10

    # Check if TOR is running by making a request through the TOR SOCKS5 proxy
    tor_status=$(curl -sS --socks5 127.0.0.1:9050 https://check.torproject.org/ | grep -o "Congratulations. This browser is configured to use Tor.")

    if [[ -n $tor_status ]]; then
        tor_status="TOR is running"
    else
        tor_status="TOR is not running"
    fi

    # Get current IP
    tor_ip=$(curl -sS https://ipinfo.io/ip)

    # Display the data in tabular format
    display_row "$timestamp" "$tor_status" "$tor_ip"
}

start() {
    if [[ -f $PIDFILE ]]; then
        echo "Script is already running."
        exit 1
    fi

    echo "Starting TOR IP changer..."
    display_header
    (
        while true; do
            change_tor_ip
            sleep 10
        done
    ) &
    echo $! > $PIDFILE
    echo "TOR IP changer started with PID $(cat $PIDFILE)."
}

stop() {
    if [[ -f $PIDFILE ]]; then
        PID=$(cat $PIDFILE)
        echo "Stopping TOR IP changer with PID $PID..."
        kill $PID
        rm -f $PIDFILE
        echo "TOR IP changer stopped."
    else
        echo "No running instance found."
        exit 1
    fi
}

status() {
    if [[ -f $PIDFILE ]]; then
        PID=$(cat $PIDFILE)
        if ps -p $PID > /dev/null; then
            echo "TOR IP changer is running with PID $PID."
        else
            echo "PID file found but no running instance. Cleaning up..."
            rm -f $PIDFILE
            exit 1
        fi
    else
        echo "TOR IP changer is not running."
    fi
}

case $1 in
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        exit 1
        ;;
esac
