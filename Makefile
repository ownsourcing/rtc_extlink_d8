# config per https://docs.tugboat.qa/examples/drupal8/ 2018-03-02
packages:
	# following lines from search that lead to https://docs.tugboat.qa/build-script/examples/install-php72/
  apt-get install -y python-software-properties software-properties-common
  add-apt-repository -y ppa:ondrej/php
  apt-get update
  apt-get install -y php7.2
	# following lines from example config
	apt-get install -y mysql-client rsync wget
	# Install drush-launcher. This assumes you are using composer to install
	# your desired version of Drush.
	wget -O /usr/local/bin/drush https://github.com/drush-ops/drush-launcher/releases/download/0.5.1/drush.phar
	chmod +x /usr/local/bin/drush
	composer install

drupalconfig:
	cp /var/www/html/sites/default/tugboat.settings.php /var/www/html/sites/default/settings.local.php
	echo "\$$settings['hash_salt'] = '$$(openssl rand -hex 32)';" >> /var/www/html/sites/default/settings.local.php

createdb:
	mysql -h mysql -u tugboat -ptugboat -e "create database rtc_extlink_d8;"

importdb:
	scp -P 2222 -o PubkeyAuthentication=yes intme@ime-client.com:tugboat/rtc_extlink_d8/backup-2018-03-07T04-39-22rtc_extlink_d8.mysql.gz /tmp/backup-2018-03-07T04-39-22rtc_extlink_d8.mysql.gz
	zcat /tmp/backup-2018-03-07T04-39-22rtc_extlink_d8.mysql.gz | mysql -h mysql -u tugboat -ptugboat rtc_extlink_d8

importfiles:
	rsync -av --delete intme@ime-client.com:tugboat/rtc_extlink_d8/files/ /var/www/html/sites/default/files/
	chgrp -R www-data /var/www/html/sites/default/files
	find /var/www/html/sites/default/files -type d -exec chmod 2775 {} \;
	find /var/www/html/sites/default/files -type f -exec chmod 0664 {} \;

stagefileproxy:
	drush -r /var/www/html pm-download stage_file_proxy
	drush -r /var/www/html pm-enable --yes stage_file_proxy
	drush -r /var/www/html variable-set stage_file_proxy_origin "http://www.example.com"

build:
	drush -r /var/www/html cache-rebuild

cleanup:
	apt-get clean
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## If syncing files directly into a Tugboat Preview
# partial success; run just the previously-failed steps
# tugboat-init: drupalconfig build cleanup
tugboat-init: packages createdb drupalconfig importdb importfiles build cleanup
tugboat-update: importdb importfiles build cleanup
tugboat-build: build

## If using Stage File Proxy to serve files
#tugboat-init: packages createdb drupalconfig importdb stagefileproxy build cleanup
#tugboat-update: importdb stagefileproxy build cleanup
#tugboat-build: build
