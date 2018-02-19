#!/usr/bin/env bash

IPWEB1="10.0.2.20"
IPWEB2="10.0.2.21"
IPDB1="10.0.3.20"
IPDB2="10.0.3.21"
IPDBBALANCER="10.0.3.25"

NGINXCONF='
upstream php {
	server unix:/var/run/php5-fpm.sock;
	server 127.0.0.1:9000;
}

server {
	## Your website name goes here.
	listen [::]:80 ipv6only=off default_server;
	server_name _;
	root /var/www/wordpress;
	index index.php;

	location = /favicon.ico {
		log_not_found off;
		access_log off;
	}

	location = /robots.txt {
		allow all;
		log_not_found off;
		access_log off;
	}

	location / {
		try_files $uri $uri/ /index.php?$args;
	}

	location ~ \.php$ {
		include fastcgi_params;
		fastcgi_intercept_errors on;
		fastcgi_pass php;
	}

	location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
		expires max;
		log_not_found off;
	}
}
'

echo -e ">"
echo -e "\t=============================================="
echo -e "\t=== ESV UE2 Wordpress (PHP, nginx) install ==="
echo -e "\t=============================================="
echo -e "\t== do not use this in production!... please =="
echo -e "\t=============================================="
echo -e ">"

#shortcuts for apt-get
APTGET="apt-get -y"
APTGETSIM="apt-get -y -s"

#environment variables
TZ="Europe/Vienna"
TERM="dumb"
DEBIAN_FRONTEND="noninteractive"
export TZ=$TZ
export TERM=$TERM
export DEBIAN_FRONTEND=$DEBIAN_FRONTEND

#update
$APTGET update
#$APTGET upgrade

#$APTGET install software-properties-common

#mariadb repo
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
add-apt-repository -y 'deb http://mirror.23media.de/mariadb/repo/10.0/ubuntu trusty main'

#nginx repo
wget http://nginx.org/keys/nginx_signing.key
apt-key add nginx_signing.key
add-apt-repository -y 'deb http://nginx.org/packages/debian/ codename nginx'

#php repo
add-apt-repository -y 'ppa:ondrej/php5-5.6'

#install php and nginx
$APTGET install nginx php5-fpm php5-cli php5-mysql mariadb-client

#install wp-cli
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

#create wordpress dir
mkdir /var/www
mkdir /var/www/wordpress
cd /var/www/wordpress

#download wordpress
wp --allow-root --path="/var/www/wordpress/" core download --locale=en_US

#config wordpress
MYSQLHOST=$IPDBBALANCER
wp --allow-root --path="/var/www/wordpress/" core config --dbhost=$IPDBBALANCER --dbname="wordpress" --dbuser="esv" # --dbpass="enterpriseservices"

#install wordpress
wp --allow-root --path="/var/www/wordpress/" core install --url="137.116.205.228" --title="ESV UE2" --admin_user="admin" --admin_password="enterpriseservices" --admin_email="admin@sahand.ss"

#set permissions
useradd -G www-data nginx
chown -R www-data:www-data /var/www
chmod -R 770 /var/www

echo -e "$NGINXCONF" > /etc/nginx/conf.d/default.conf
rm -rf /etc/nginx/sites-enabled
service nginx restart

ufw default deny

ufw allow ssh
ufw allow 80

ufw --force enable
ufw reload

reboot

exit 0
