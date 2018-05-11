#!/bin/bash

# PHP version to be installed supplied by command line argument
version=$1

# Navigate to script's working directory 
cd "$(dirname "$0")"

# Checking for a missing argument
if (( $# != 1 ))
then
  echo "Missing PHP version argument!"
  echo "Usage eg.: ./install 7.0.0"
  exit 1
fi

# Install Prerequisites
apt-get update
apt-get install -y \
        autoconf \
        bison \
        build-essential \
        git-core \
        libbz2-dev \
        libcurl4-openssl-dev \
        libfreetype6-dev \
        libicu-dev \
        libjpeg-dev \
        libmcrypt-dev \
        libpng-dev \
        libpspell-dev \
        libreadline-dev \
        libssl-dev \
        libxml2-dev \
        pkg-config

# Create directory to be used as an installation target
mkdir /usr/local/php-$version

git clone --single-branch --branch "PHP-$version" --depth 1 https://github.com/php/php-src.git
cd php-src

./buildconf --force

CONFIGURE_STRINGS="--enable-bcmath \
                   --enable-calendar \
                   --enable-dba \
                   --enable-exif \
                   --enable-filter \
                   --enable-fpm \
                   --enable-ftp \
                   --enable-gd-native-ttf \
                   --enable-intl \
                   --enable-mbstring \
                   --enable-mysqlnd \
                   --enable-pcntl \
                   --enable-shmop \
                   --enable-simplexml \
                   --enable-soap \
                   --enable-sockets \
                   --enable-sysvmsg \
                   --enable-sysvsem \
                   --enable-sysvshm \
                   --enable-wddx \
                   --enable-xmlreader \
                   --enable-xmlwriter \
                   --enable-zip \
                   --prefix=/usr/local/php-$version \
                   --with-bz2 \
                   --with-config-file-scan-dir=/usr/local/php-$version/etc/conf.d \
                   --with-curl \
                   --with-fpm-group=www-data \
                   --with-fpm-user=www-data \
                   --with-freetype-dir \
                   --with-gd \
                   --with-gettext \
                   --with-jpeg-dir \
                   --with-mcrypt \
                   --with-mhash \
                   --with-mysqli=mysqlnd \
                   --with-mysql-sock=/var/run/mysqld/mysqld.sock \
                   --with-openssl \
                   --without-pear \
                   --with-pdo-mysql=mysqlnd \
                   --with-pdo-sqlite \
                   --with-png-dir \
                   --with-pspell \
                   --with-readline \
                   --with-sqlite3 \
                   --with-zlib"

./configure $CONFIGURE_STRINGS

# Perform compilation and subsequent installation
make
make install

# Configure PHP-FPM
cd ..
for i in $( ls conf/* ); do sed -i "s/VERSION/$version/" $i; done
ln -s /usr/local/php-$version/sbin/php-fpm /usr/local/php-$version/sbin/php-$version-fpm
cp php-src/php.ini-production /usr/local/php-$version/lib/php.ini
mv /usr/local/php-$version/etc/php-fpm.d/www.conf.default /usr/local/php-$version/etc/php-fpm.d/www.conf
cp conf/php-fpm.conf /usr/local/php-$version/etc/php-fpm.conf

# Enable modules
echo "zend_extension=opcache.so" >> /usr/local/php-$version/lib/php.ini

# Configure php7-fmp init.d script
cp conf/php7-fpm.init /etc/init.d/php7-fpm
chmod +x /etc/init.d/php7-fpm
update-rc.d php7-fpm defaults
