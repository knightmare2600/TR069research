Step by step to install a Web Server SSL certificate 

About StartSSL: I don't know much about StartSSL, but they seem serious. They've been in business for many years and if you want to get some higher level certificates they will probably be pretty thorough about getting your passports, driver's license, code, phone numbers, etc. With that in mind, I think it's pretty safe to use these certificates.

1. Login to startssl.com and sign up. StartSSL will verify your email-address in this step. You will create a browser-ceritificate in this step, in order for your browser to login to StartSSL (that's why you don't see a password prompt!)
2. Go to Validations Wizard and choose Domain Name Validation. Go through the steps carefully. Save all kinds of keys/output. Document what you do - you will forget it the next minute! For domain validation to work, StartSSL will search for an email addresse connected to you domain. Probably StartSSL.com runs the "whois <domainname>" command and search for email addresses there. Then StartSSL will send you a code to one of those email addresses, and you must post that back into the web.
3. Go to Certificate Wizard and choose "Web Server SSL/TLS Certificate". Go through the steps carefully. Save all kinds of keys/output. Document what you do - you will forget it the next minute! At last you'll have a so called .pem file with the certificate. 

From this point on, it's all about loading this certificate into the keystore (yes - certificates can be loaded into keystores! - isn't it wonderful how these terms "keys" and "certificates" are inter-mingled?!) so that Tomcat (or any other server) can use the certificates. This process is probably very easy for those who really know what they're doing. Since I'm in not in that group, here's what I need to do:

4. Download the files found in http://freeacs.com/downloads/StartSSL (wget -r --no-parent -l1 --no-directories http://freeacs.com/downloads/StartSSL (you may get some strange index-files from this command, just delete them)
5. You should receive 5 files, of which you will use 3. I am assuming you requested a class 1 certificate from StartSSL in the following:
6. Of your decrypted! private key (created in step 3), make a file with this filename: <HOSTNAME>.key (example: freeacs.mycomp.com.key)
7. Of your certificate received in step 3, make a file with this filename: <HOSTNAME>.crt (example: freeacs.mycomp.com.crt)
8. Run the following command to see the required arguments: build_jks_class1.sh
9. One example of correct args could be:
./build_jks_class1.sh freeacs.mycomp.com.crt mypass myalias mykeystore

If you haven't done the slightest mistake above, no spaces have crept into your certificates, no newlines or conversion issues happening in the copying, etc - then! everything should work out, and you would have created a brand new keystore called mykeystore with exactly one certificate loaded into it. You can check for yourself using this command:

keytool -list -keystore mykeystore -storepass mypass

At this stage we're always very happy! 

10. Copy mykeystore into /var/lib/tomcat7
11. Now open /etc/tomcat7/server.xml and locate the Connector for SSL (port 8443 usually)
12. Change port to 443. Add the following attributes to the tag:

keystoreFile="/var/lib/tomcat7/mykeystore"
keystorePass="mypass"
keyAlias="myAlias"

....save file and restart server... check catalina.out (on Tomcat) and test


13. Assuming everything works at this point, now it's time to consider a few things:
- The certificate you installed on the server applies to all clients connecting on port 443, both devices and browsers alike. Is this something you want? If not, maybe consider splitting FreeACS into multiple servers/hosts?
- The certificate you installed must be auto-accepted by the device (if it connects over SSL), or it must be compiled into the firmware. The certificate you installed has probably a year lifespan, and you do not - ABSOLUTELY NOT - want to change the certificate one the devices every year. Therefore it could be a smart idea to compile into the CPE a higher-level certificate (check your browser to view the certificate chain), which has a much longer lifespan. 
- The certificate you installed has a dependency chain defined by using the files startssl*.pem. These files are the some years old now, and maybe StartSSL can offer newer ones - to get longer lifespan.

With these considerations I which you luck:)














