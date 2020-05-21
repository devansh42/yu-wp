Service to backup wordpress site data
## This service uses /var/wp/backup-sites file which contains list of sites to backup
## Every site data is mounted at /var/wp/html/:siteid (can be found in /var/wp/sites) 

# Environment Variables for WP Backup Service

|Name|Remark|
|DO_ACCESS_KEY|DO Access key |
|DO_SECRET_KEY| DO Secret Key|
|DO_BUCKET|DO Bucket endpoint|
|DO_BUCKET_NAME|DO Bucket Name|

