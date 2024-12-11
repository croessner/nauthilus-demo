# Nauthilus Demo

This little demo shows Nauthilus in action. It is used as an authentication backend in Dovecot. Furthermore, it deals
as a director replacement in Dovecot.

> Note
> 
> Nauthilus can do much more and the demo is stripped down! See full documentation to learn more about Nauthilus

The demo includes a Docker stack with a Dovecot frontend server and two backends, Nauthilus and Valkey.

## Requirements

* Docker and the compose plugin

Optional for testing:

* curl
* swaks
* jq

## Runn it

```shell
docker compose up -d
```

There is a test script called **nauthilus-test.sh**:

```shell
./nauthilus-test.sh
```

It should output something like this:

```
###
############# Deliver test email
###

=== Trying 127.0.0.1:2400...
=== Connected to 127.0.0.1.
<-  220 eb3b3af7868b Dovecot ready.
 -> LHLO rns-macbook-pro-2019.fritz.box
<-  250-eb3b3af7868b
<-  250-8BITMIME
<-  250-CHUNKING
<-  250-ENHANCEDSTATUSCODES
<-  250 PIPELINING
 -> MAIL FROM:<test@example.com>
<-  250 2.1.0 OK
 -> RCPT TO:<testuser>
<-  250 2.1.5 OK
 -> DATA
<-  354 OK
 -> Date: Wed, 11 Dec 2024 11:08:40 +0100
 -> To: testuser
 -> From: test@example.com
 -> Subject: test Wed, 11 Dec 2024 11:08:40 +0100
 -> Message-Id: <20241211110840.044550@rns-macbook-pro-2019.fritz.box>
 -> X-Mailer: swaks v20240103.0 jetmore.org/john/code/swaks/
 ->
 -> This is a test mailing
 ->
 ->
 -> .
<-  250 2.0.0 <testuser> iHlIBqhkWWcVAAAA30tcPg Saved
 -> QUIT
<-  221 2.0.0 Bye
=== Connection closed with remote host.

###
############# Test request to Nauthilus
###

*   Trying 127.0.0.1:8080...
* Connected to 127.0.0.1 (127.0.0.1) port 8080
> POST /api/v1/auth/json?mode=no-auth HTTP/1.1
> Host: 127.0.0.1:8080
> User-Agent: curl/8.7.1
> Content-Type: application/json
> Accept: application/json
> Content-Length: 283
>
} [283 bytes data]
* upload completely sent off: 283 bytes
< HTTP/1.1 200 OK
< Auth-Status: OK
< Auth-User: testaccount
< Content-Type: application/json; charset=utf-8
< X-Nauthilus-Memory-Cache: Miss
< X-Nauthilus-Session: 2q4AxYDTHOhHUVX5IJaOA5Pdlmi
< Date: Wed, 11 Dec 2024 10:08:40 GMT
< Content-Length: 193
<
{ [193 bytes data]
* Connection #0 to host 127.0.0.1 left intact
{
  "passdb_backend": 3,
  "account_field": "account",
  "totp_secret_field": null,
  "webauth_userid_field": null,
  "display_name_field": null,
  "attributes": {
    "Proxy-Host": [
      "backend-2"
    ],
    "account": [
      "testaccount"
    ]
  }
}

###
############# Fetch newest email from Dovecot
###

Return-Path: <test@example.com>
Delivered-To: testaccount
Received: from eb3b3af7868b ([172.23.0.5])
	by e40d06dcd37e with LMTP
	id KE3PBqhkWWcTAAAABgCKxQ
	(envelope-from <test@example.com>)
	for <testaccount>; Wed, 11 Dec 2024 10:08:40 +0000
Received: from rns-macbook-pro-2019.fritz.box ([172.23.0.1])
	by eb3b3af7868b with LMTP
	id iHlIBqhkWWcVAAAA30tcPg
	(envelope-from <test@example.com>)
	for <testuser>; Wed, 11 Dec 2024 10:08:40 +0000
Date: Wed, 11 Dec 2024 11:08:40 +0100
To: testuser
From: test@example.com
Subject: test Wed, 11 Dec 2024 11:08:40 +0100
Message-Id: <20241211110840.044550@rns-macbook-pro-2019.fritz.box>
X-Mailer: swaks v20240103.0 jetmore.org/john/code/swaks/

This is a test mailing
```
