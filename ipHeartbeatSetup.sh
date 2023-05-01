#!/bin/bash
# Writes a file `ipHeartbeat.sh` to run as a cronjob . `ipHeartbeat` checks the current IP address against previous stored value.
# If the IPs are different, the script updates both A records (www. and regular) for the website

# Some initial setup is required as described in README.txt 

touch /home/$USER/.ip
ip -o a|grep -E 'inet '|grep -v '127.0.0.1'|awk {'print $4'}|cut -d/ -f1 > /home/$USER/.ip

# Install dependencies
sudo apt install jq

# pull everything below up to `EOF` into the ipHeartbeat.sh file 
cat <<'EOF' >/home/"$USER"/ipHeartbeat.sh
#!/bin/bash
USER=$(whoami)
CURL=$(which curl)
IP_FILE="/home/$USER/.ip"
RECORD_VARS_FILE="recordVars.txt"
OUTPUT_FILE="output.txt"
TOKENS_FILE="/home/$USER/.tokens"

# Define a function to update DNS records
update_dns_record() {
    local id="$1"
    local type="$2"
    local zone_id="$3"
    local zone_name="$4"
    local name="$5"
    local ip="$6"

    echo "Updating DNS record for $name with IP $ip"

    # cURL request to update DNS record
    "$CURL" --request PATCH \
        --url "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$id" \
        --header "Content-Type: application/json" \
        --header "Authorization: Bearer $TOKEN_EDIT_DNS_AUTH" \
        --data '{
        "comment": "Domain verification record",
        "content": "'"$ip"'",
        "name": "'"$name"'",
        "proxied": false,
        "ttl": 3600
        }'
}

# Load the Auth token
if [ -f "$TOKENS_FILE" ]; then
    source "$TOKENS_FILE"
else
    echo "ERROR: Tokens file not found" >&2
    exit 1
fi

# Check current IP address against stored IP
ip_val=$(cat "$IP_FILE")
echo "Current IP address is $ip_val"

ip_val_heartbeat="$(ip -o a | grep -E 'inet ' | grep -v '127.0.0.1' | awk '{print $4}' | cut -d/ -f1)"
echo "Heartbeat IP address is $ip_val_heartbeat"

if [ "$ip_val" != "$ip_val_heartbeat" ]; then
    ip_val="$ip_val_heartbeat"
    echo "IP addresses are different. Updating DNS records..."

    # Parse JSON and update DNS records
    while read -r id; do
        type=$(jq ".result[] | select(.id == $id) | .type" "$RECORD_VARS_FILE")
        if [ "$type" == "\"A\"" ]; then
            zone_id=$(jq ".result[] | select(.id == $id) | .zone_id" "$RECORD_VARS_FILE")
            zone_name=$(jq ".result[] | select(.id == $id) | .zone_name" "$RECORD_VARS_FILE")
            name=$(jq ".result[] | select(.id == $id) | .name" "$RECORD_VARS_FILE")

            # Remove leading and trailing double quotes from variables
            zone_id="${zone_id%\"}"
            zone_id="${zone_id#\"}"
            id="${id%\"}"
            id="${id#\"}"
            name="${name%\"}"
            name="${name#\"}"

            update_dns_record "$id" "$type" "$zone_id" "$zone_name" "$name" "$ip_val" >> "$OUTPUT_FILE"
        fi
    done <<< "$(jq '.result[].id' "$RECORD_VARS_FILE")"

    echo "$ip_val" > "$IP_FILE"
else
    echo "IP addresses are the same. No need to update DNS records."
fi
EOF