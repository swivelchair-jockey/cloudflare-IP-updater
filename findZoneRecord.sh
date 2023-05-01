
# what is the DNS record identifier?
# zoneID is found in CloudFlare website


curl -X GET "https://api.cloudflare.com/client/v4/zones/{ZoneID}/dns_records" \
     -H "Content-Type:application/json" \
     -H "Authorization:Bearer $TOKEN_EDIT_DNS_AUTH"
     
