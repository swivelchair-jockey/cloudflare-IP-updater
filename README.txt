The script checks the current IP address against the previous stored value.
If the update are different updates both A DNS records (www. and regular) for the website


SETUP - 
1. Save CloudFlare DNS Auth token (40 alphanumeric chars) into a new file `/home/$USER/.tokens` in the format:
`export TOKEN_EDIT_DNS_AUTH=qwertyuiop123_0123456789Q-qwer0123456789`

2. Make sure dependencies `cURL` and `jq` (a 'prettifier' for json that will make grepping easier)

3. Find your ZoneID by looking at CloudFlare dashboard - this is $zone_id used below

4. Find the DNS record identifier for each DNS record to change. This is done by running:

. /home/$USER/.tokens
curl -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
     -H "Content-Type:application/json" \
     -H "Authorization: Bearer $TOKEN_EDIT_DNS_AUTH" \
     | jq > recordVars.txt

5. Saves the output as recordVars.txt in the same place as your other files - this will be used to populate the ipHeartbeatSetup.sh 

