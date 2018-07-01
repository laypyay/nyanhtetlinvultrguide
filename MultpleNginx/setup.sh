#!/bin/bash
apt-get update && apt-get upgrade -y
apt install build-essential make libgeoip-dev libbz2-dev libreadline-dev sudo -y
CompileDir=/tmp
dirYouWantToInstall=/PkgRoot
pcreurl=https://ftp.pcre.org/pub/pcre/pcre-8.42.tar.gz
zliburl=https://zlib.net/zlib-1.2.11.tar.gz
opensslurl=https://www.openssl.org/source/openssl-1.1.1-pre8.tar.gz
nginxurl=http://nginx.org/download/nginx-1.14.0.tar.gz
nginxversion=1.14.0
nginxuser=webuser
nginxgroup=webuser
mkdir -p -m777 $CompileDir
mkdir -p -m777 $CompileDir/tmp
mkdir -p -m777 $dirYouWantToInstall
mkdir -p -m777 $dirYouWantToInstall/nginx
mkdir -p -m777 $dirYouWantToInstall/nginx/$nginxversion
mkdir -p -m777 $dirYouWantToInstall/nginx/$nginxversion/conf
mkdir -p -m777 $dirYouWantToInstall/nginx/$nginxversion/log
mkdir -p -m777 $dirYouWantToInstall/nginx/$nginxversion/system
cd $CompileDir/tmp
rm -r *
wget $pcreurl -O pcre.tar.gz
tar -zxf pcre.tar.gz
rm pcre.tar.gz
mv pcre* pcre
wget $zliburl -O zlib.tar.gz
tar -zxf zlib.tar.gz
rm zlib.tar.gz
mv zlib* zlib
wget $opensslurl -O openssl.tar.gz
tar -zxf openssl.tar.gz
rm openssl.tar.gz
mv openssl* openssl
wget $nginxurl -O nginx.tar.gz
tar -zxf nginx.tar.gz
rm nginx.tar.gz
mv nginx* nginx
cd nginx
./configure \
--prefix=$dirYouWantToInstall/nginx/$nginxversion \
--pid-path=$dirYouWantToInstall/nginx/$nginxversion/system/nginx.pid \
--conf-path=$dirYouWantToInstall/nginx/$nginxversion/conf/nginx.conf \
--error-log-path=$dirYouWantToInstall/nginx/$nginxversion/log/error.log \
--http-log-path=$dirYouWantToInstall/nginx/$nginxversion/log/log.log \
--lock-path=$dirYouWantToInstall/nginx/$nginxversion/nginx.lock \
--with-pcre=$CompileDir/tmp/pcre \
--with-zlib=$CompileDir/tmp/zlib \
--with-openssl=$CompileDir/tmp/openssl \
--user=$nginxuser \
--group=$nginxgroup \
--with-threads \
--with-file-aio \
--with-http_ssl_module \
--with-http_v2_module \
--with-http_realip_module \
--with-http_geoip_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_slice_module \
--with-mail \
--with-mail_ssl_module \
--with-stream \
--with-stream_ssl_module \
--with-stream_realip_module \
--with-stream_geoip_module
make -j${nproc}
make install
cat << EOT >> $dirYouWantToInstall/nginx/$nginxversion/system/nginx
#!/bin/sh
### BEGIN INIT INFO
# Provides:          nginx
# Required-Start:    \$local_fs \$remote_fs \$network \$syslog
# Required-Stop:     \$local_fs \$remote_fs \$network \$syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the nginx web server
# Description:       starts nginx using start-stop-daemon
### END INIT INFO
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:${dirYouWantToInstall}/nginx/${nginxversion}/sbin
DAEMON=$dirYouWantToInstall/nginx/$nginxversion/sbin/nginx
PID_FILE=$dirYouWantToInstall/nginx/$nginxversion/system/nginx.pid
NAME=nginx
DESC=nginx
# Include nginx default if available
if [ -f /etc/default/nginx ]; then
	. /etc/default/nginx
fi
test -x \$DAEMON || exit 0
set -e
. /lib/lsb/init-functions
test_nginx_config() {
	if \$DAEMON -t \$DAEMON_OPTS >/dev/null 2>&1; then
		return 0
	else
		\$DAEMON -t \$DAEMON_OPTS
		return \$?
	fi
}
case "\$1" in
	start)
		echo -n "Starting \$DESC: "
		test_nginx_config
		# Check if the ULIMIT is set in /etc/default/nginx
		if [ -n "\$ULIMIT" ]; then
			# Set the ulimits
			ulimit \$ULIMIT
		fi
		start-stop-daemon --start --quiet --pidfile \$PID_FILE \
			--exec \$DAEMON -- \$DAEMON_OPTS || true
		echo "\$NAME."
		;;
	stop)
		echo -n "Stopping \$DESC: "
		start-stop-daemon --stop --quiet --pidfile \$PID_FILE \
			--exec \$DAEMON || true
		echo "\$NAME."
		;;
	restart|force-reload)
		echo -n "Restarting \$DESC: "
		start-stop-daemon --stop --quiet --pidfile \
			\$PID_FILE --exec \$DAEMON || true
		sleep 1
		test_nginx_config
		# Check if the ULIMIT is set in /etc/default/nginx
		if [ -n "\$ULIMIT" ]; then
			# Set the ulimits
			ulimit \$ULIMIT
		fi
		start-stop-daemon --start --quiet --pidfile \
			\$PID_FILE --exec \$DAEMON -- \$DAEMON_OPTS || true
		echo "\$NAME."
		;;
	reload)
		echo -n "Reloading \$DESC configuration: "
		test_nginx_config
		start-stop-daemon --stop --signal HUP --quiet --pidfile \$PID_FILE \
			--exec \$DAEMON || true
		echo "\$NAME."
		;;
	configtest|testconfig)
		echo -n "Testing \$DESC configuration: "
		if test_nginx_config; then
			echo "\$NAME."
		else
			exit \$?
		fi
		;;
	status)
		status_of_proc -p \$PID_FILE "\$DAEMON" nginx && exit 0 || exit \$?
		;;
	*)
		echo "Usage: \$NAME {start|stop|restart|reload|force-reload|status|configtest}" >&2
		exit 1
		;;
esac
exit 0
EOT
chown -fR $nginxuser:$nginxgroup $dirYouWantToInstall/nginx/$nginxversion
chmod -fR 755 $dirYouWantToInstall/nginx/$nginxversion
chmod -fR +x $dirYouWantToInstall/nginx/$nginxversion
rm -f /usr/bin/nginxv
cat << EOT >> /usr/bin/nginxv
#!/bin/bash
if [ ! \$1 ]; then
		echo \$'\nUsage : \n\tnginxv [VersionNumber]\n\nVersionNumber : The number you wrote in setup.sh\n'
else
	if [ -f $dirYouWantToInstall/nginx/\$1/system/nginx ]; then
		if [ -f /etc/init.d/nginx ]; then
			service nginx stop
			chmod -x /etc/init.d/nginx
			rm /etc/init.d/nginx
		fi
		cp $dirYouWantToInstall/nginx/\$1/system/nginx /etc/init.d/nginx
		chmod +x /etc/init.d/nginx
		update-rc.d nginx defaults
		systemctl daemon-reload
		service nginx start
		echo "Nginx Version Was Changed to "\$1
	else
		echo "Invalid Nginx version. \""\$1"\" version of nginx was not installed."
	fi
fi
EOT
chmod -f 755 /usr/bin/nginxv
chmod -f +x /usr/bin/nginxv
cat << EOT

*********************************
Configuration files Location
*********************************
Nginx version $nginxversion was successfully installed.
Version :				$nginxversion
Installdir :			$dirYouWantToInstall/nginx/$nginxversion
Configuration File :	$dirYouWantToInstall/nginx/$nginxversion/conf/nginx.conf
LogFiles :				$dirYouWantToInstall/nginx/$nginxversion/log
initscript :			$dirYouWantToInstall/nginx/$nginxversion/system/nginx

EOT
