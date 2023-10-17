#!/usr/bin/env bash
set -euf -o pipefail

cd "$(dirname "$0")/../secrets/" || exit

function usage {
    printf "Usage:\n"
    printf "$0 [--prompt|-p]\n"
    exit 1
}

function argparse {
  while [ $# -gt 0 ]; do
    case "$1" in
      --prompt|-p)
        # optional: activate prompt for certificate trust with keytool (default: no prompt)
        export NO_PROMPT=""
        shift
        ;;
      *)
        printf "ERROR: Parameters invalid\n"
        usage
    esac
  done
}

#
# init
export NO_PROMPT="-noprompt"
argparse $*

echo "🔖  Generating some fake certificates and other secrets."
[[ -z "$NO_PROMPT" ]] && echo "⚠️  Remember to type in \"yes\" for all prompts."
sleep 2

TLD="local"
PASSWORD="awesomekafka"
COUNTRY_CODE="AU"

CA_NAME="fake-ca-1"

# Generate CA key
openssl req -new -x509 -keyout ${CA_NAME}.key \
	-out ${CA_NAME}.crt -days 9999 \
	-subj "/CN=ca1.${TLD}/OU=CIA/O=REA/L=Melbourne/ST=VIC/C=${COUNTRY_CODE}" \
	-passin pass:$PASSWORD -passout pass:$PASSWORD

for i in broker control-center metrics schema-registry kafka-tools rest-proxy; do
	echo ${i}
	# Create keystores
	keytool -genkey -noprompt \
		-alias ${i} \
		-dname "CN=${i}.${TLD}, OU=CIA, O=REA, L=Melbourne, ST=VIC, C=${COUNTRY_CODE}" \
		-keystore kafka.${i}.keystore.jks \
		-keyalg RSA \
		-storepass $PASSWORD \
		-keypass $PASSWORD

	# Create CSR, sign the key and import back into keystore
	keytool ${NO_PROMPT} -keystore kafka.$i.keystore.jks -alias $i -certreq -file $i.csr -storepass $PASSWORD -keypass $PASSWORD

	openssl x509 -req -CA ${CA_NAME}.crt -CAkey ${CA_NAME}.key -in $i.csr -out $i-ca1-signed.crt -days 9999 -CAcreateserial -passin pass:$PASSWORD

	keytool ${NO_PROMPT} -keystore kafka.$i.keystore.jks -alias CARoot -import -file ${CA_NAME}.crt -storepass $PASSWORD -keypass $PASSWORD

	keytool ${NO_PROMPT} -keystore kafka.$i.keystore.jks -alias $i -import -file $i-ca1-signed.crt -storepass $PASSWORD -keypass $PASSWORD

	# Create truststore and import the CA cert.
	keytool ${NO_PROMPT} -keystore kafka.$i.truststore.jks -alias CARoot -import -file ${CA_NAME}.crt -storepass $PASSWORD -keypass $PASSWORD

	echo $PASSWORD >${i}_sslkey_creds
	echo $PASSWORD >${i}_keystore_creds
	echo $PASSWORD >${i}_truststore_creds
done

echo "✅  All done."
