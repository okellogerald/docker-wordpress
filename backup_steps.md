> NOTES: `./mysql` and `./wordpress` are volumes to store all WordPress and MySQL related content. This is specified in the Docker Compose file.

## Backup Steps

1. First, create a backup directory:
    ```bash
    mkdir -p ~/Downloads/backup
    ```

2. Create a database dump (this is more reliable than copying the MySQL directory):
    ```bash
    docker exec ${container-id} mysqldump -u root -p"${MYSQL_ROOT_PASSWORD}" ${MYSQL_DATABASE} > ~/Downloads/backup/mysql_dump.sql
    ```

3. Backup WordPress files:
    ```bash
    cp -r ./wordpress ~/Downloads/backup/wordpress
    ```

4. Backup configuration files:
    ```bash
    cp docker-compose.yml ~/Downloads/backup/
    cp .env ~/Downloads/backup/
    cp backup_steps.md ~/Downloads/backup/
    ```

## Restore Steps

1. Stop containers:
    ```bash
    docker-compose down
    ```

2. Restore WordPress files:
    ```bash
    cp -r ~/Downloads/backup/wordpress ./
    ```

3. Start containers:
    ```bash
    docker-compose up -d
    ```

4. Restore the database:
    ```bash
    cat ~/Downloads/backup/mysql_dump.sql | docker exec -i ${container-id} mysql -u root -p"${MYSQL_ROOT_PASSWORD}"
    ```

5. Check the `wordpress/wp-config.php` file to make sure wp variables are defined correctly
    ```
    define( 'DB_HOST', 'mysql:3306' ); // check in your docker compose
    define( 'DB_NAME', 'wordpress'); // mysql db name
    define( 'DB_USER', 'wp_admin' ); // if this user does not exist in mysql, you can create it and grant it all priviledges for the mysql db
    define( 'DB_PASSWORD', 'y0koq6wclfa2y5u' ); // you can create a mysql db with this password
    define('WP_HOME', 'http://localhost:8000'); // has to be full localhost url like this
    define('WP_SITEURL', 'http://localhost:8000'); // has to be full localhost url like this
    ```

## Publish to Remote Server

1. **CPANEL**: Create a database (if one doesn't exist), e.g., `wordpress`.
2. **CPANEL**: Create a user who will have access to this database, e.g., `admin`.
3. **PHPMYADMIN**: Select the database you created, import `mysql_dump.sql` dump file.
4. **FILEMANAGER**: Copy the local WordPress folder contents to the `public_html` directory.
5. **FILEMANAGER**: Within `wp-config.php`, edit the following:
    ```php
    define( 'DB_HOST', 'localhost' );
    /** The created Database name or the existing one you found */
    define( 'DB_NAME', 'wordpress'); // The (actual) name of the database. The name in the mysql-dump file may be different from the one you create in PHPMyAdmin. In this case, the name of the database to be used is the one on mysql-dump file. The one set on PHPMyAdmin acts as a placeholder only to point to the real database
    /** The DB User you created and assigned to the database */
    define( 'DB_USER', 'jamaahos_temboplus' ); // The name of the user you created and assigned to the created database in PHPMyAdmin
    define( 'DB_PASSWORD', 'iHjT53vY2M' ); // The password you assigned to that user you created in PHPMyAdmin
    /** The website. This avoids automatic redirects */
    define( 'WP_HOME', 'https://jamaahost.com/' ); // the URL with the correct domain being used
    define( 'WP_SITEURL', 'https://jamaahost.com/' ); // the URL with the correct domain being used
    ```
6. Login to WordPress with the username and password you used locally.

CPANEL (temboplus.com)
db_name: wordpress
username: wp_admin /wordpress db user/
password: y0koq6wclfa2y5u /wordpress db user password/ 

WORDPRESS (temboplus.com/wp-admin)
username:admin
password:onmrpkgxp

> To login into phpMyAdmin locally use "root" username and the root-password