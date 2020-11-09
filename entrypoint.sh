#!/bin/ash
set -e

# If the ENV variables should be printed or not
export DEBUG=${DEBUG:-"false"}

# Export restart command for BIND (Used in watchdog script)
export DNS_RESTART=${DNS_RESTART:-"rndc reload"}

# ENV to skip IPv4 and IPv6
export SKIP_IPV4=${SKIP_IPV4:-"false"}
export SKIP_IPV6=${SKIP_IPV6:-"false"}

# Detect IPv4 and IPv6 addresses
export IPV4=${IPV4:-$(ip route get 1.1.1.1 2> /dev/null | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')}
export IPV6=${IPV6:-$(ip route get 2606:4700:4700::1111 2> /dev/null | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')}

export REDIRECT_IPV4=${REDIRECT_IPV4:-IPV4}
export REDIRECT_IPV6=${REDIRECT_IPV6:-IPV6}

if [ "$DEBUG" != "false" ]; then
  echo "=== DEBUG ====================================================="
  echo "DNS_RESTART: $DNS_RESTART"
  echo "SKIP_IPV4: $SKIP_IPV4"
  echo "SKIP_IPV6: $SKIP_IPV6"
  echo "IPV4: $IPV4"
  echo "IPV6: $IPV6"
  echo "REDIRECT_IPV4: $REDIRECT_IPV4"
  echo "REDIRECT_IPV6: $REDIRECT_IPV6"
  echo "==============================================================="
fi

if [ -z "$IPV4" ] && [ -z "$IPV6" ]; then
  echo "[!] Could not detect IP address"
  exit 1
fi

# Generate zone files
#echo "[-] Generating zone files"
#python3 /opt/dns-config-watchdog/main.py --skip-refresh

# Run watchdog on zones.json in background
#python3 /opt/dns-config-watchdog/main.py --watchdog &

# Replace ${IPV4} and ${IPV6} in `/etc/bind/named.conf.options`
if [ "$SKIP_IPV4" != "false" ]; then
  echo "[!] Skipping IPv4 support"
elif [ -n "$IPV4" ]; then
  echo "[+] IPv4 set to $IPV4"
  #sed -i "s/\/\/listen-on port 53 { \${IPV4}; };/listen-on port 53 { $IPV4; };/g" /etc/bind/named.conf.options
  echo "*       IN A $IPV4" >> /etc/bind/any.zone;
else
  echo "[!] No IPv4 support"
fi

if [ "$SKIP_IPV6" != "false" ]; then
  echo "[!] Skipping IPv6 support"
elif [ -n "$IPV6" ]; then
  echo "[+] IPv6 set to $IPV6"
  #sed -i "s/\/\/listen-on-v6 port 53 { \${IPV6}; };/listen-on-v6 port 53 { $IPV6; };/g" /etc/bind/named.conf.options
  echo "*       IN AAAA $IPV6" >> /etc/bind/any.zone;
else
  echo "[!] No IPv6 support"
fi

# Start BIND
echo "[-] BIND Starting..."
named -c /etc/bind/named.conf -u named&
