#!/bin/bash

# Array of DNS servers you want to cycle through
DNS_SERVERS=("8.8.8.8" "1.1.1.1" "9.9.9.9")

# Get the primary network interface
INTERFACE=$(networksetup -listallnetworkservices | sed -n '2p')

# Function to change DNS server
change_dns() {
    local dns=$1
    echo "Changing DNS to $dns"
    sudo networksetup -setdnsservers "$INTERFACE" $dns
}

# Function to get the current IP address from Tor
get_tor_ip() {
    curl --socks5-hostname 127.0.0.1:9050 -s https://check.torproject.org/ | grep -oP '(?<=Your IP address appears to be )[0-9\.]+'
}

# Function to change the TOR IP
change_tor_ip() {
    echo "Changing TOR IP..."
    sudo killall -HUP tor
    sleep 10
}

# Function to log the current status
log_status() {
    local status=$1
    local dns=$2
    local tor_ip=$(get_tor_ip)
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    printf "%-20s | %-20s | %-15s\n" "$timestamp" "$status" "$dns" "$tor_ip"
}

# Print the header of the log table
printf "%-20s | %-20s | %-15s | %-15s\n" "Timestamp" "Status" "DNS Server" "TOR IP"

# Main loop to change DNS and TOR IP
while true; do
    for dns in "${DNS_SERVERS[@]}"; do
        change_dns $dns
        change_tor_ip
        log_status "TOR IP Changed" $dns
        sleep 60 # Wait for 60 seconds before changing again
    done
done
