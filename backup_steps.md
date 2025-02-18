> NOTES: ./mysql and ./wordpress are volumes to store all wordpress and mysql related content. This is specified in the docker-compose file

1. First, create a backup directory:
```bash
mkdir -p ~/Downloads/tembopluscom_backup
```

2. Create a database dump (this is more reliable than copying the mysql directory):
```bash
docker exec ${container-id} mysqldump -u root -p"${MYSQL_ROOT_PASSWORD}" ${MYSQL_DATABASE} > ~/Downloads/tembopluscom_backup/mysql_dump.sql
```

3. Backup WordPress files:
```bash
cp -r ./wordpress ~/Downloads/tembopluscom_backup/wordpress
```

4. Backup configuration:
```bash
cp docker-compose.yml ~/Downloads/tembopluscom_backup/
cp .env ~/Downloads/tembopluscom_backup/
cp backup_steps.md ~/Downloads/tembopluscom_backup/
```

To restore from this backup:
1. Stop containers:
```bash
docker-compose down
```

2. Restore WordPress files:
```bash
cp -r ~/Downloads/tembopluscom_backup/wordpress ./
```

3. Start containers:
```bash
docker-compose up -d
```

4. Restore the database:
```bash
cat ~/Downloads/tembopluscom_backup/mysql_dump.sql | docker exec -i ${container-id} mysql -u root -p"${MYSQL_ROOT_PASSWORD}"
```

To publish to the remote server:
1. CPANEL: Create a database (if one doesn't exist) e.g wordpress
2. CPANEL: Create a user who will have access to this database e.g admin
3. PHPMYADMIN: Select the database you created, import mysql_dump.sql dump file
4. FILEMANAGER: Copy the local wordpress folder contents to `public_html` directory
5. FILEMANAGER: Within `wp-config.php`, edit the following:
```php
define( 'DB_HOST', 'localhost' );
/** The created Database name or the existing one you found */
define( 'DB_NAME', 'wordpress'); // The (actual) name of the database. The name in the mysql-dump file may be different from the one you create in PHPMyAdmin. In this case, the name of the database to be used is the one on mysql-dump file. The one set on PHPMyAdmin acts as a placeholder only to point to the real database
/** The DB User you created and assigned to the database */
define( 'DB_USER', 'jamaahos_temboplus' ); // The name of the user you created and assigned to the created database in PHPMyAdmin
define( 'DB_PASSWORD', 'iHjT53vY2M' ); // The password you assigned to that user you created in PHPMyAdmin
/** The website. This avoids automatic redirects */
define( 'WP_HOME', 'https://jamaahost.com/' ); // the url with the correct domain being used
define( 'WP_SITEURL', 'https://jamaahost.com/' ); // the url with the correct domain being used
```
1. Login in wordpress with the username and password you used locally