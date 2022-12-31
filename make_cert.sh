#/bin/bash

rm -rf ssl
mkdir ssl
openssl genrsa 2048 > ssl/nginx.key
openssl req -new -key ssl/nginx.key -subj "/C=JP/ST=Tokyo/O=Personal Company/CN=my-company.com" > ssl/nginx.csr
openssl x509 -days 3650 -req -extfile subjectnames.txt -signkey ssl/nginx.key < ssl/nginx.csr > ssl/nginx.crt

