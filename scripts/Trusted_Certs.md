+ Open a webpage that uses the CA with Firefox
+ Click the lock-icon in the addressbar -> show information -> show certificate
+ the certificate viewer will open
+ click details and choose the certificate of the certificate-chain, you want to import to CentOS
+ click "Export..." and save it as .crt file
+ Copy the .crt file to `/etc/pki/ca-trust/source/anchors` on your CentOS machine
+ run `update-ca-trust extract`
+ test it with `wget https://thewebsite.org`


On debian and ubuntu the directory is `/usr/local/share/ca-certificates/` and the command to update is `update-ca-certificates`
