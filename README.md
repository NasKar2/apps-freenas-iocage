# apps-freenas-iocage

Script to create an iocage jail on Freenas 11.1U4 from scratch with sonarr, radarr, lidarr, sabnzbd, and plex.

All apps will be placed in the same jail with separate data directories for each app to allow for easy reinstallation/backup.

Thanks to Pentaflake for his work on installing these apps in an iocage jail 

https://forums.freenas.org/index.php?resources/fn11-1-iocage-jails-plex-tautulli-sonarr-radarr-lidarr-jackett-ombi-transmission-organizr.58/

### Prerequisites
Edit file mono-config

Edit mono-config file with your network information and directory data name you want to use and location of your media files and torrents.

SONARR_DATA="sonarrdata" will create a data directory /mnt/v1/apps/sonarrdata to store all the data for that app and the same for the others.

MEDIA_LOCATION will set the location of your media files, in this example /mnt/v1/media

TORRENTS_LOCATION will set the location of your torrent files, in this example /mnt/v1/torrents

PLEX_TYPE needs to be set to plexpass or plex depending on which version you want.

For example SONARR_DATA="sonarrdata" will create a data directory /mnt/v1/apps/sonarrdata to store all the data for that app.

```
JAIL_IP="192.168.5.57"
DEFAULT_GW_IP="192.168.5.1"
INTERFACE="igb0"
VNET="off"
POOL_PATH="/mnt/v1"
JAIL_NAME="plexapps"
SONARR_DATA="sonarrdata2"
RADARR_DATA="radarrdata2"
LIDARR_DATA="lidarrdata2"
SABNZBD_DATA="sabnzbddata2"
PLEX_DATA="plexdata2"
MEDIA_LOCATION="media"
TORRENTS_LOCATION="torrents"
PLEX_TYPE="plexpass"
```
## Install Plex and related apps in fresh Jail

Create an iocage jail to install sonarr, radarr, lidarr, sabnzbd and plex.

Then run this command
```
./install.sh
```

## After Script completes
Run Sabnzbd wizard
Add to Sonarr, Radarr, Lidarr a Indexer, Download Client, and Connect (Plex).
Set Media Management to Rename movies and optionally Permissions to yes with File chmod mask 0660, Folder chmod mask 0770, chown User:media, chown Group:media
Plex follow steps including adding libraries.  If metadata(thumbnails) doesn't download move Local Media Assets to the bottom of the list in server/settings/agents/shows/TheTVDB etc.  
