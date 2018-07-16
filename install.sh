#!/bin/sh
# Build an iocage jail under FreeNAS 11.1 with  Sonarr, Radarr, Lidarr and Plex
# https://github.com/NasKar2/apps-freenas-iocage

# Check for root privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Initialize defaults
JAIL_IP=""
DEFAULT_GW_IP=""
INTERFACE=""
VNET="off"
POOL_PATH=""
JAIL_NAME=""
SONARR_DATA=""
RADARR_DATA=""
LIDARR_DATA=""
SABNZBD_DATA=""
PLEX_DATA=""
MEDIA_LOCATION=""
TORRENTS_LOCATION=""
PLEX_TYPE="plexpass"

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
. $SCRIPTPATH/mono-config
CONFIGS_PATH=$SCRIPTPATH/configs

# Check for mono-config and set configuration
if ! [ -e $SCRIPTPATH/mono-config ]; then
  echo "$SCRIPTPATH/mono-config must exist."
  exit 1
fi

# Check that necessary variables were set by mono-config
if [ -z $JAIL_IP ]; then
  echo 'Configuration error: JAIL_IP must be set'
  exit 1
fi
if [ -z $DEFAULT_GW_IP ]; then
  echo 'Configuration error: DEFAULT_GW_IP must be set'
  exit 1
fi
if [ -z $INTERFACE ]; then
  echo 'Configuration error: INTERFACE must be set'
  exit 1
fi
if [ -z $POOL_PATH ]; then
  echo 'Configuration error: POOL_PATH must be set'
  exit 1
fi

if [ -z $JAIL_NAME ]; then
  echo 'Configuration error: JAIL_NAME must be set'
  exit 1
fi

if [ -z $SONARR_DATA ]; then
  echo 'Configuration error: SONARR_DATA must be set'
  exit 1
fi

if [ -z $RADARR_DATA ]; then
  echo 'Configuration error: RADARR_DATA must be set'
  exit 1
fi

if [ -z $LIDARR_DATA ]; then
  echo 'Configuration error: LIDARR_DATA must be set'
  exit 1
fi

if [ -z $SABNZBD_DATA ]; then
  echo 'Configuration error: SABNZBD_DATA must be set'
  exit 1
fi

#if [ -z $PLEX_DATA ]; then
#  echo 'Configuration error: PLEX_DATA must be set'
#  exit 1
#fi

if [ "$PLEX_TYPE" != "plex" ] && [ "$PLEX_TYPE" != "plexpass" ]; then
  echo '${PLEX_TYPE} Configuration error: PLEX_DATA must be set to plex or plexpass'
  echo ${PLEX_TYPE}
  exit 1
fi

if [ -z $MEDIA_LOCATION ]; then
  echo 'Configuration error: MEDIA_LOCATION must be set'
  exit 1
fi

if [ -z $TORRENTS_LOCATION ]; then
  echo 'Configuration error: TORRENTS_LOCATION must be set'
  exit 1
fi

#
# Create Jail
echo '{"pkgs":["nano","mono","mediainfo","sqlite3","ca_root_nss","curl"]}' > /tmp/pkg.json
iocage create --name "${JAIL_NAME}" -p /tmp/pkg.json -r 11.1-RELEASE ip4_addr="${INTERFACE}|${JAIL_IP}/24" defaultrouter="${DEFAULT_GW_IP}" boot="on" host_hostname="${JAIL_NAME}" vnet="${VNET}"

rm /tmp/pkg.json

#
# needed for installing from ports
#mkdir -p ${PORTS_PATH}/ports
#mkdir -p ${PORTS_PATH}/db

mkdir -p ${POOL_PATH}/apps/${SONARR_DATA}
mkdir -p ${POOL_PATH}/apps/${RADARR_DATA}
mkdir -p ${POOL_PATH}/apps/${LIDARR_DATA}
mkdir -p ${POOL_PATH}/apps/${SABNZBD_DATA}
mkdir -p ${POOL_PATH}/apps/${PLEX_DATA}
mkdir -p ${POOL_PATH}/${MEDIA_LOCATION}
mkdir -p ${POOL_PATH}/${TORRENTS_LOCATION}
echo "mkdir -p '${POOL_PATH}/apps/${SONARR_DATA}'"
echo "mkdir -p '${POOL_PATH}/apps/${SABNZBD_DATA}'"

sonarr_config=${POOL_PATH}/apps/${SONARR_DATA}
radarr_config=${POOL_PATH}/apps/${RADARR_DATA}
lidarr_config=${POOL_PATH}/apps/${LIDARR_DATA}
sabnzbd_config=${POOL_PATH}/apps/${SABNZBD_DATA}
plex_config=${POOL_PATH}/apps/${PLEX_DATA}
#iocage exec ${JAIL_NAME} mkdir -p /mnt/configs
iocage exec ${JAIL_NAME} 'sysrc ifconfig_epair0_name="epair0b"'

#
# mount ports so they can be accessed in the jail
#iocage fstab -a ${JAIL_NAME} ${PORTS_PATH}/ports /usr/ports nullfs rw 0 0
#iocage fstab -a ${JAIL_NAME} ${PORTS_PATH}/db /var/db/portsnap nullfs rw 0 0

iocage fstab -a ${JAIL_NAME} ${CONFIGS_PATH} /mnt/configs nullfs rw 0 0
iocage fstab -a ${JAIL_NAME} ${POOL_PATH}/apps /config nullfs rw 0 0
iocage fstab -a ${JAIL_NAME} ${POOL_PATH}/${MEDIA_LOCATION} /mnt/media nullfs rw 0 0
iocage fstab -a ${JAIL_NAME} ${POOL_PATH}/${TORRENTS_LOCATION} /mnt/torrents nullfs rw 0 0

iocage restart ${JAIL_NAME}
  
# add media group to media user
#iocage exec ${JAIL_NAME} pw groupadd -n media -g 8675309
#iocage exec ${JAIL_NAME} pw groupmod media -m media
#iocage restart ${JAIL_NAME} 

#
# Make media owner of data directories
#chown -R media:media $sonarr_config/
#chown -R media:media $radarr_config/
#chown -R media:media $lidarr_config/
#chown -R media:media $sabnzbd_config/
#chown -R plex:plex $plex_config/
#chown -R media:media ${POOL_PATH}/${MEDIA_LOCATION}
#chown -R media:media ${POOL_PATH}/${TORRENTS_LOCATION}

#
# Install Radarr
iocage exec ${JAIL_NAME} mkdir -p /mnt/torrents/sabnzbd/incomplete
iocage exec ${JAIL_NAME} mkdir -p /mnt/torrents/sabnzbd/complete
iocage exec ${JAIL_NAME} ln -s /usr/local/bin/mono /usr/bin/mono
iocage exec ${JAIL_NAME} "fetch https://github.com/Radarr/Radarr/releases/download/v0.2.0.995/Radarr.develop.0.2.0.995.linux.tar.gz -o /usr/local/share"
iocage exec ${JAIL_NAME} "tar -xzvf /usr/local/share/Radarr.*.linux.tar.gz -C /usr/local/share"
iocage exec ${JAIL_NAME} rm /usr/local/share/Radarr.develop.0.2.0.995.linux.tar.gz

#
# Make media the user of the jail and create group media and make media a user of the that group
iocage exec ${JAIL_NAME} "pw user add media -c media -u 8675309  -d /nonexistent -s /usr/bin/nologin"
#iocage exec ${JAIL_NAME} "pw groupadd -n media -g 8675309"
iocage exec ${JAIL_NAME} "pw groupmod media -m media"

#
#Install Radarr
iocage exec ${JAIL_NAME} chown -R media:media /usr/local/share/Radarr /config/${RADARR_DATA}
iocage exec ${JAIL_NAME} -- mkdir /usr/local/etc/rc.d
iocage exec ${JAIL_NAME} cp -f /mnt/configs/radarr /usr/local/etc/rc.d/radarr
iocage exec ${JAIL_NAME} chmod u+x /usr/local/etc/rc.d/radarr
iocage exec ${JAIL_NAME} sed -i '' "s/radarrdata/${RADARR_DATA}/" /usr/local/etc/rc.d/radarr
iocage exec ${JAIL_NAME} sysrc "radarr_enable=YES"
iocage exec ${JAIL_NAME} service radarr start
echo "Radarr installed"

#
# Install Sonarr
#iocage exec ${JAIL_NAME} ln -s /usr/local/bin/mono /usr/bin/mono
iocage exec ${JAIL_NAME} "fetch http://download.sonarr.tv/v2/master/mono/NzbDrone.master.tar.gz -o /usr/local/share"
iocage exec ${JAIL_NAME} "tar -xzvf /usr/local/share/NzbDrone.master.tar.gz -C /usr/local/share"
iocage exec ${JAIL_NAME} -- rm /usr/local/share/NzbDrone.master.tar.gz
#iocage exec ${JAIL_NAME} "pw user add media -c media -u 8675309  -d /nonexistent -s /usr/bin/nologin"
iocage exec ${JAIL_NAME} chown -R media:media /usr/local/share/NzbDrone /config/${SONARR_DATA}
#iocage exec ${JAIL_NAME} -- mkdir /usr/local/etc/rc.d
iocage exec ${JAIL_NAME} cp -f /mnt/configs/sonarr /usr/local/etc/rc.d/sonarr
iocage exec ${JAIL_NAME} chmod u+x /usr/local/etc/rc.d/sonarr
iocage exec ${JAIL_NAME} sed -i '' "s/sonarrdata/${SONARR_DATA}/" /usr/local/etc/rc.d/sonarr
iocage exec ${JAIL_NAME} sysrc "sonarr_enable=YES"
iocage exec ${JAIL_NAME} service sonarr start
echo "Sonarr installed"

#
# Install Lidarr
iocage exec ${JAIL_NAME} "fetch https://github.com/lidarr/Lidarr/releases/download/v0.2.0.371/Lidarr.develop.0.2.0.371.linux.tar.gz -o /usr/local/share"
iocage exec ${JAIL_NAME} "tar -xzvf /usr/local/share/Lidarr.develop.*.linux.tar.gz -C /usr/local/share"
iocage exec ${JAIL_NAME} rm /usr/local/share/Lidarr.develop.0.2.0.371.linux.tar.gz
#iocage exec ${JAIL_NAME} "pw user add lidarr -c lidarr -u 353 -d /nonexistent -s /usr/bin/nologin"
iocage exec ${JAIL_NAME} chown -R media:media /usr/local/share/Lidarr /config/${LIDARR_DATA}
#iocage exec ${JAIL_NAME} mkdir /usr/local/etc/rc.d
iocage exec ${JAIL_NAME} cp -f /mnt/configs/lidarr /usr/local/etc/rc.d/lidarr
iocage exec ${JAIL_NAME} chmod u+x /usr/local/etc/rc.d/lidarr
iocage exec ${JAIL_NAME} chown -R media:media /usr/local/etc/rc.d/lidarr
iocage exec ${JAIL_NAME} sed -i '' "s/lidarrdata/${LIDARR_DATA}/" /usr/local/etc/rc.d/lidarr
iocage exec ${JAIL_NAME} sysrc "lidarr_enable=YES"
iocage exec ${JAIL_NAME} service lidarr start

echo "lidarr installed"

#
# Make pkg upgrade get the latest repo
iocage exec ${JAIL_NAME} mkdir -p /usr/local/etc/pkg/repos/
iocage exec ${JAIL_NAME} cp -f /mnt/configs/FreeBSD.conf /usr/local/etc/pkg/repos/FreeBSD.conf

#
# Upgrade to the lastest repo
iocage exec ${JAIL_NAME} pkg upgrade -y
iocage restart ${JAIL_NAME}

#
# Install Sabnzbd
iocage exec ${JAIL_NAME} pkg install -y sabnzbdplus
iocage exec ${JAIL_NAME} ln -s /usr/local/bin/python2.7 /usr/bin/python
iocage exec ${JAIL_NAME} ln -s /usr/local/bin/python2.7 /usr/bin/python2
iocage exec ${JAIL_NAME} "pw groupmod media -m _sabnzbd"
iocage exec ${JAIL_NAME} chown -R media:media /mnt/torrents/sabnzbd /config/${SABNZBD_DATA}
iocage exec ${JAIL_NAME} sysrc "sabnzbd_user=media"
iocage exec ${JAIL_NAME} sysrc sabnzbd_enable=YES
iocage exec ${JAIL_NAME} sysrc sabnzbd_conf_dir="/config/${SABNZBD_DATA}"
iocage exec ${JAIL_NAME} cp -f /mnt/configs/sabnzbd /usr/local/etc/rc.d/sabnzbd
#echo "sabnzbd_data ${SABNZBD_DATA}"
iocage exec ${JAIL_NAME} sed -i '' "s/sabnzbddata/${SABNZBD_DATA}/" /usr/local/etc/rc.d/sabnzbd
iocage exec ${JAIL_NAME} sed -i '' "s/sabnzbdpid/${SABNZBD_DATA}/" /usr/local/etc/rc.d/sabnzbd

iocage restart ${JAIL_NAME}
iocage exec ${JAIL_NAME} service sabnzbd start
iocage exec ${JAIL_NAME} service sabnzbd stop
iocage exec ${JAIL_NAME} sed -i '' -e 's?host = 127.0.0.1?host = 0.0.0.0?g' /config/${SABNZBD_DATA}/sabnzbd.ini
iocage exec ${JAIL_NAME} sed -i '' -e 's?download_dir = Downloads/incomplete?download_dir = /mnt/torrents/sabnzbd/incomplete?g' /config/${SABNZBD_DATA}/sabnzbd.ini
iocage exec ${JAIL_NAME} sed -i '' -e 's?complete_dir = Downloads/complete?complete_dir = /mnt/torrents/sabnzbd/complete?g' /config/${SABNZBD_DATA}/sabnzbd.ini
iocage exec ${JAIL_NAME} service sabnzbd start

echo "Sabnzbd installed"

#
# Install Plex
if [ $PLEX_TYPE == "plexpass" ]; then
   echo "plexpass to be installed"
   iocage exec ${JAIL_NAME} pkg install -y plexmediaserver-plexpass
   iocage exec ${JAIL_NAME} sysrc "plexmediaserver_plexpass_enable=YES"
   iocage exec ${JAIL_NAME} sysrc plexmediaserver_plexpass_support_path="/config/${PLEX_DATA}"
   iocage exec ${JAIL_NAME} chown -R plex:plex /config/${PLEX_DATA}
   iocage exec ${JAIL_NAME} chmod -R 760 /config/${PLEX_DATA}
   iocage exec ${JAIL_NAME} "pw groupmod media -m plex"
   iocage exec ${JAIL_NAME} service plexmediaserver_plexpass start
else
   echo "plex to be installed"
   iocage exec ${JAIL_NAME} pkg install -y plexmediaserver
   iocage exec ${JAIL_NAME} sysrc "plexmediaserver_enable=YES"
   iocage exec ${JAIL_NAME} sysrc plexmediaserver_support_path="/config/${PLEX_DATA}"
   iocage exec ${JAIL_NAME} chown -R plex:plex /config/${PLEX_DATA}
   iocage exec ${JAIL_NAME} chmod -R 760 /config/${PLEX_DATA}
   iocage exec ${JAIL_NAME} "pw groupmod media -m plex"
   iocage exec ${JAIL_NAME} service plexmediaserver start
fi

echo "${PLEX_TYPE} installed"

#
# remove /mnt/configs as no longer needed
#iocage fstab -r ${JAIL_NAME} ${CONFIGS_PATH} /mnt/configs nullfs rw 0 0

echo
echo "Radarr should be available at http://${JAIL_IP}:7878"
echo "Sonarr should be available at http://${JAIL_IP}:8989"
echo "lidarr should be available at http://${JAIL_IP}:8686"
echo "sabnzbd should be available at http://${JAIL_IP}:8080"
echo "${PLEX_TYPE} should be available at http://${JAIL_IP}:32400/web/index.html"

