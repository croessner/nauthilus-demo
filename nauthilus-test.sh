#!/bin/bash

echo "###"
echo "############# Deliver test email"
echo "###"
echo
swaks --protocol LMTP --server 127.0.0.1:2400 --from test@example.test --to testuser@foobar.test

echo
echo "###"
echo "############# Test request to Nauthilus"
echo "###"
echo
curl -v -s -H "Content-Type: application/json" -H "Accept: application/json" -d @request.json http://127.0.0.1:8080/api/v1/auth/json?mode=no-auth | jq

echo
echo "###"
echo "############# Fetch newest email from Dovecot"
echo "###"
echo
curl -s --user "testuser:testpassword" --url "imap://127.0.0.1:1430/INBOX;UID=*"

exit 0
