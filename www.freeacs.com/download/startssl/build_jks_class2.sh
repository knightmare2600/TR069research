#!/bin/bash
#
# v1.0 - 29.10.2010 Jon Suphammer <js@pingcom.net>
# v1.1 - 17.02.2011 Morten Simonsen (morten@pingcom.net)
# v1.2 - 21.11.2011 Morten Simonsen (morten@pingcom.net) 
#		- support class2 certs
#		- bugfix on validation-check
#
# $1 = crt-filename
# $2 = password to be used in the keystore
# $3 = alias 
# $4 = keystore filename


if [ $# -ne 4 ]
then
	echo "Usage: $0 <crt-filename> <password> <alias> <keystore>"
	echo ""
	echo "<crt-filename>   The filename of the crt-file you have received from"
	echo "                 StartSSL. This file must be found in the same directory"
	echo "                 as this build_jks-script."
	echo "<password>       This password will be used in the keystore. "
	echo "                 Make sure to use the same password in server.xml"
	echo "<alias>          The alias will be used in the keystore. "
	echo "                 Make sure to use the same alias in server.xml."
	echo "<keystore>       The name of the keystore. You can specify an existing"
	echo "                 keystore or a new one. Make sure to use this"
	echo "                 keystore in server.xml."
	exit -1
fi

if [ ! -e startssl_sub.class2.server.ca.pem ]
then
	echo "Missing file 'startssl_sub.class2.server.ca.pem', this file must" 
	echo "be found in this directory. The file is available from StartSSL, but"
	echo "should also be part of the xAPS pacakge. The file is a standard public"
	echo "key for StartSSL."
	exit -1
fi

if [ ! -e startssl_ca.pem ]
then
        echo "Missing file 'startssl_ca.pem', this file must"
        echo "be found in this directory. The file is available from StartSSL, but"
        echo "should also be part of the xAPS pacakge. The file is a standard public"
        echo "key for StartSSL."
	exit -1
fi

if [ ! -e $1 ] 
then
	echo "Missing file '$1', expected the crt-file that you must have recevied"
	echo "from StartSSL. This file should be found in this directory."
	exit -1
fi

CRTFILENAME=$1
HOST=${CRTFILENAME%\.*}
PASS=$2
ALIAS=$3
KEYSTORE=$4

if [ ! -e ${HOST}.key ]
then
        echo "Missing file '${HOST}.key', expected the key-file that you must have recevied"
        echo "from StartSSL. This file should be found in this directory."
        exit -1
fi


#rm -f certs/${HOST}.jks

cat ${HOST}.crt startssl_sub.class2.server.ca.pem startssl_ca.pem > ${HOST}.chn &&
echo "${PASS}" | openssl pkcs12 -export -inkey ${HOST}.key -in ${HOST}.chn -out ${HOST}.pkcs12 -passout stdin -name ${ALIAS} &&
keytool -importkeystore -srckeystore ${HOST}.pkcs12 -srcstoretype PKCS12 -destkeystore ${KEYSTORE} -srcstorepass ${PASS} -deststorepass ${PASS} -alias ${ALIAS} 
#rm -f certs/${HOST}.pkcs12 certs/${HOST}.chn

