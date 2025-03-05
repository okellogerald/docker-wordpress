# WordPress Docker Backup and Restore Documentation

> NOTES: `./mysql` and `./wordpress` are volumes to store all WordPress and MySQL related content. This is specified in the Docker Compose file.

## Backup Steps

1. First, create a backup directory:
    ```bash
    mkdir -p ~/Downloads/backup
    ```

2. Create a database dump (this is more reliable than copying the MySQL directory):
    ```bash
    docker exec MYSQL_CONTAINER_NAME mysqldump -u root -p"YOUR_ROOT_PASSWORD" YOUR_DATABASE_NAME > ~/Downloads/backup/mysql_dump.sql
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
    cat ~/Downloads/backup/mysql_dump.sql | docker exec -i MYSQL_CONTAINER_NAME mysql -u root -p"YOUR_ROOT_PASSWORD" YOUR_DATABASE_NAME
    ```

5. Check the `wordpress/wp-config.php` file to make sure WordPress variables are defined correctly:
    ```php
    define('DB_HOST', 'mysql:3306'); // Use your Docker service name with port
    define('DB_NAME', 'your_database_name'); // MySQL database name
    define('DB_USER', 'your_database_user'); // MySQL user
    define('DB_PASSWORD', 'your_secure_password'); // MySQL user password
    define('WP_HOME', 'http://localhost:8000'); // Full localhost URL with port
    define('WP_SITEURL', 'http://localhost:8000'); // Full localhost URL with port
    ```

## Publish to Remote Server

1. **CPANEL**: Create a database (if one doesn't exist)
2. **CPANEL**: Create a user with appropriate permissions for this database
3. **PHPMYADMIN**: Select the database you created, import `mysql_dump.sql` dump file
4. **FILEMANAGER**: Copy the local WordPress folder contents to the `public_html` directory
5. **FILEMANAGER**: Within `wp-config.php`, edit the following:
    ```php
    define('DB_HOST', 'localhost');
    define('DB_NAME', 'cpanel_database_name'); // The name of your CPanel database
    define('DB_USER', 'cpanel_database_user'); // The CPanel database user
    define('DB_PASSWORD', 'secure_password'); // The password for your CPanel database user
    define('WP_HOME', 'https://yourdomain.com'); // Your actual domain
    define('WP_SITEURL', 'https://yourdomain.com'); // Your actual domain
    ```
6. Login to WordPress with your admin credentials

## Administrator Access

- To access phpMyAdmin locally, use the credentials specified in your environment variables
- For WordPress admin access, use the admin credentials you created during installation

## Security Notes

- Store all passwords securely (consider using a password manager)
- Never share database credentials or WordPress admin passwords
- Use strong, unique passwords for all accounts
- Consider using environment variables for sensitive information
- Regularly update your backup to maintain recent copies of your site
