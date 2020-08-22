#!/bin/bash

# Get the location of this script in order to find the san.cnf file
scriptDir=$(dirname $0)

#
# Create self-signed certificate with Subject Alternative Name (SAN) extension
#
# See https://medium.com/@antelle/how-to-generate-a-self-signed-ssl-certificate-for-an-ip-address-f0dd8dddf754
#
mkdir -p reg_certs

# Setup self-signed certificate using SAN
openssl req -x509 -nodes -days 730 -newkey rsa:4096 -keyout reg_certs/key.pem -out reg_certs/cert.pem -config $scriptDir/san.cnf
ok=$?


# Display cert info
openssl x509 -in reg_certs/cert.pem -text -noout