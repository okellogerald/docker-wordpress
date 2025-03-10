# WordPress Backup and Restore Guide

This guide explains how to backup, restore, and publish your WordPress site using the included Makefile automation tools. It also covers how to set up a new WordPress project from scratch.

## Creating a New WordPress Project

The easiest way to set up a new WordPress project is to clone the ready-made repository:

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/okellogerald/docker-wordpress my-wordpress-site
   cd my-wordpress-site
   ```

2. **Customize Environment Variables**:
   Edit the `.env` file to customize your settings:
   ```bash
   nano .env
   ```
   Update values for:
   - MYSQL_ROOT_PASSWORD
   - MYSQL_DATABASE
   - MYSQL_USER
   - MYSQL_PASSWORD

3. **Create secrets.txt**:
   Create a file named `secrets.txt` to store your WordPress admin credentials:
   ```
   WordPress Admin Username: admin
   WordPress Admin Password: your_admin_password
   WordPress Admin Email: your.email@example.com
   ```

4. **Start the Containers**:
   ```bash
   docker-compose up -d
   ```

5. **Complete WordPress Installation**:
   - Open your browser and navigate to http://localhost:8000
   - Follow the WordPress installation wizard
   - Use the credentials from your secrets.txt file

6. **Make Your First Backup**:
   ```bash
   make backup
   ```

The repository comes with everything you need, including:
- Preconfigured docker-compose.yml
- Properly set up Makefile for backup and restore
- Default environment configuration
- Directory structure for WordPress and MySQL

Now your WordPress project is set up and ready for development!

## Prerequisites

- Docker and Docker Compose installed
- Make utility installed
- Git (optional, for version control)

## Creating a Backup

To create a complete backup of your WordPress site:

> **Important**: The backup includes a "secrets.txt" file containing your WordPress admin credentials. Keep this backup secure as it contains sensitive information.

1. Make sure your Docker containers are running:
   ```bash
   docker-compose up -d
   ```

2. Run the backup command:
   ```bash
   make backup
   ```

3. The backup process will:
   - Create a MySQL database dump
   - Copy all WordPress files
   - Include configuration files (.env, docker-compose.yml)
   - Create a ZIP archive in the ~/Downloads/temp/ directory
   - The final backup file will be named: `site_backup_DD_MM_YYYY.zip`

## Restoring from a Backup

To restore your WordPress site from a backup:

1. Unzip the backup file:
   ```bash
   unzip site_backup_DD_MM_YYYY.zip
   ```

2. Navigate to the extracted directory:
   ```bash
   cd site_backup_DD_MM_YYYY/
   ```

3. Run the restore command:
   ```bash
   make restore
   ```

4. The restore process will:
   - Check for required backup files
   - Start Docker containers
   - Prompt you for the MySQL container ID (displayed in the console)
   - Prompt you for the WordPress port (either accept the suggested port or enter a custom one)
   - Restore the database
   - Update WordPress configuration
   - Display the URL where your site is accessible

   > **Note**: If you can't access the homepage (e.g., "http://localhost:8000"), try accessing the admin area directly (e.g., "http://localhost:8000/wp-admin"). If the admin area works but the homepage doesn't, try opening your site in a fresh browser window.

## Publishing to a Remote Server

To publish your WordPress site to a remote server (like cPanel):

### 1. Prepare cPanel Environment

1. **Create a Database in cPanel**:
   - Log in to your cPanel account
   - Navigate to "MySQL® Databases"
   - Create a new database (e.g., `username_wordpress`)

2. **Create a Database User**:
   - In the same "MySQL® Databases" section
   - Create a new user with a secure password
   - Add the user to the database with "All Privileges"

### 2. Import Database

1. **Access phpMyAdmin**:
   - From cPanel, open phpMyAdmin
   - Select the database you created

2. **Import Database**:
   - Click the "Import" tab
   - Select the `mysql_dump.sql` file from your backup
   - Click "Go" to import

### 3. Upload Files

1. **Access File Manager**:
   - In cPanel, open "File Manager"
   - Navigate to the `public_html` directory (or subdirectory if using a subdomain)

2. **Upload WordPress Files**:
   - Upload all contents from the `wordpress` directory in your backup
   - You can use the File Manager upload tool or FTP for larger sites

### 4. Configure WordPress

1. **Edit wp-config.php**:
   - Locate and edit the `wp-config.php` file in your site root
   - Update the following settings:

   ```php
   define('DB_HOST', 'localhost');
   define('DB_NAME', 'cpanel_database_name'); // The name of your cPanel database
   define('DB_USER', 'cpanel_database_user'); // The cPanel database user
   define('DB_PASSWORD', 'secure_password'); // The password for your cPanel database user
   define('WP_HOME', 'https://yourdomain.com'); // Your actual domain
   define('WP_SITEURL', 'https://yourdomain.com'); // Your actual domain
   ```

2. **Set Permissions**:
   - Set appropriate file permissions:
   - Directories: 755
   - Files: 644
   - wp-config.php: 600 (for extra security)

### 5. Complete Installation

1. **Access Your Site**:
   - Navigate to your domain in a web browser
   - Login using your WordPress admin credentials
   - If necessary, update permalinks by going to Settings > Permalinks and clicking "Save Changes"

## Administrator Access

- **Local MySQL Access**: 
  - Username: "root"
  - Password: Value of MYSQL_ROOT_PASSWORD in your .env file

- **WordPress Admin**:
  - The admin credentials are stored in the "secrets.txt" file included in your backup
  - This file contains the username and password needed to access the WordPress admin dashboard

- **cPanel Access**:
  - Database User: The value of MYSQL_USER in your .env file
  - Database Password: The value of MYSQL_PASSWORD in your .env file

## Troubleshooting

If you encounter issues during restore:

1. **Connection Issues**:
   - If "http://localhost:8000" doesn't connect, try "http://localhost:8000/wp-admin" directly
   - If wp-admin works but the homepage doesn't, try accessing the site in a fresh browser window (or incognito mode)
   - This can resolve issues related to browser caching or cookies from previous configurations

2. **Container Detection**:
   - If the MySQL container isn't automatically detected, you'll be prompted to enter the container ID manually
   - Run `docker ps` to see all running containers

2. **WordPress Configuration**:
   - If your site isn't accessible after restore, check wp-config.php for correct database settings
   - Ensure the port in WP_HOME and WP_SITEURL matches your Docker configuration

3. **Database Connection**:
   - Verify the MySQL container is running: `docker ps | grep mysql`
   - Check MySQL logs: `docker logs [mysql-container-id]`

4. **Permission Issues on Remote Server**:
   - If you encounter "Error establishing database connection", verify your database credentials
   - If you see file/directory permission errors, adjust permissions as needed

## Maintenance Recommendations

- Create regular backups using `make backup`
- Store backups in multiple locations (local and cloud storage)
- Test your backups periodically by performing a restore
- Keep your WordPress, themes, and plugins updated for security