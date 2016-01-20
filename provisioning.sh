#!/bin/bash
# script a ser ejecutado com usuario com permisos administrativos

# Instalamos Java Container
yum -y install java

# Instalamos e iniciamos Tomcat
yum -y install tomcat6
service tomcat6 start
chkconfig --level 234 tomcat on

# Sumamos o repositorio EPEL que tem os binarios do Nginx
yum -y install epel-release

# Instalamos e iniciamos Nginx
yum -y install nginx
service nginx start
chkconfig --level 234 nginx on

# creamos directorio para certificado do web server
mkdir -p /etc/nginx/ssl
cd /etc/nginx/ssl

# generamos uma passphrase para o certificado
export PASSPHRASE=$(head -c 500 /dev/urandom | tr -dc a-z0-9A-Z | head -c 128; echo)
# creamos a chave privada
openssl genrsa -des3 -out ejemplo.key -passout env:PASSPHRASE 2048

# Generamos a informacao do Subject do certificado
subject="
C=BR
ST=MinasGerais
LocalityName=Uberlandia
O=Zup
OU=TI
CommonName=www.zup.com.br
EmailAddress=admin@zup.com.br
"

# generamos o CSR (certificate signing request)
openssl req -new -batch -subj "$(echo -n "$subject" | tr "\n" "/")" -key zup.key \
    -out zup.csr -passin env:PASSPHRASE

# Removemos a passphrase da chave
cp ejemplo.key ejemplo.key.bak
openssl rsa -in ejemplo.key.bak -out ejemplo.key -passin env:PASSPHRASE	
	
# generamos o certificado assinado com a chave creada antes
openssl x509 -req -in ejemplo.csr -signkey ejemplo.key -out ejemplo.crt

# instalamos Git e descargamos o repositorio dos arquivos de configuracao		
yum -y install git
cd /home/config-files
git clone https://github.com/MMHoss/Centos_6.7.git /home/

# copiamos o arquivo de configuracao do Nginx
cp /home/config-files/nginx.conf /etc/nginx/nginx.conf		
nginx -s reload

# modificamos a configuracao do tomcat para recever trafego HTTPS do proxy reverso
sed -i.bkp 's/redirectPort="8443"/redirectPort="8443" scheme="https" proxyName="localhost" proxyPort="443"/' /etc/tomcat/server.xml
service tomcat restart
