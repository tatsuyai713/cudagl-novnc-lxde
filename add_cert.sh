#/bin/bash


sudo openssl x509 -in ssl/nginx.crt -out ssl/nginx.der -outform DER
sudo openssl x509 -in ssl/nginx.der -inform DER -out ssl/nginx.pem -outform pem

sudo cp ssl/nginx.pem /usr/share/ca-certificates/
sudo bash -c 'echo "nginx.pem" >> /etc/ca-certificates.conf'

sudo update-ca-certificates