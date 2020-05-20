Service to backup databases and wordpress site

# Environment Varibales for DB Backup Service
|Name|Remarks|
|----|-------|
|SQL_PASSWD|Mysql Root Password|
|PASSWD_FILE|Password file for mysql|
|DO_ACCESS_KEY|DO Access key |
|DO_SECRET_KEY| DO Secret Key|
|DO_BUCKET|DO Bucket name|

# Environment Variables for WP Backup Service
All required for DB and
|Name|Remark|
|SITE_NAME|WP Site being hosted|

# SQL Backup service consumes /var/wp/db/names file for database name to be edited