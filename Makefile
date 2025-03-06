# Makefile for WordPress Backup and Restore
# Date: $(shell date +%d/%m/%Y)

# Static Variables
BACKUP_DATE := $(shell date +%d_%m_%Y)
BACKUP_DIR := ~/Downloads/temp/site_backup_$(BACKUP_DATE)
BACKUP_ZIP := $(BACKUP_DIR).zip
MYSQL_ROOT_USER := root

# Variables derived from configuration files
MYSQL_ROOT_PASSWORD := $(shell grep MYSQL_ROOT_PASSWORD .env | cut -d '=' -f2)
MYSQL_DATABASE := $(shell grep MYSQL_DATABASE .env | cut -d '=' -f2)
WP_DB_USER := $(shell grep MYSQL_USER .env | cut -d '=' -f2)
WP_DB_USER_PASSWORD := $(shell grep MYSQL_PASSWORD .env | cut -d '=' -f2)
WORDPRESS_DB_HOST := $(shell grep WORDPRESS_DB_HOST .env | cut -d '=' -f2)

.PHONY: backup restore clean help

# Default target
help:
	@echo "WordPress Backup and Restore Makefile"
	@echo "------------------------------------"
	@echo "Available targets:"
	@echo "  backup  - Create a full backup of the website"
	@echo "  restore - Restore the website from the latest backup"
	@echo "  clean   - Remove temporary backup directories"
	@echo "  help    - Display this help message"

# Backup target
backup:
	@echo "Starting backup process..."
	@# Get MySQL container ID at runtime
	$(eval MYSQL_CONTAINER_ID := $(shell docker ps -qf "name=mysql"))
	@if [ -z "$(MYSQL_CONTAINER_ID)" ]; then \
		echo "Error: MySQL container not found. Ensure Docker containers are running."; \
		exit 1; \
	fi
	mkdir -p $(BACKUP_DIR)
	@echo "Creating MySQL dump..."
	docker exec $(MYSQL_CONTAINER_ID) mysqldump -u $(MYSQL_ROOT_USER) -p"$(MYSQL_ROOT_PASSWORD)" $(MYSQL_DATABASE) > $(BACKUP_DIR)/mysql_dump.sql
	@echo "Copying WordPress files..."
	cp -r ./wordpress $(BACKUP_DIR)/wordpress
	@echo "Copying configuration files..."
	cp docker-compose.yml $(BACKUP_DIR)/
	cp .env $(BACKUP_DIR)/
	cp .gitignore $(BACKUP_DIR)/
	cp secrets.txt $(BACKUP_DIR)/ 2>/dev/null || true
	cp Makefile $(BACKUP_DIR)/ 2>/dev/null || true
	# Before zipping, change to the parent directory of BACKUP_DIR
	@echo "Creating ZIP archive..."
	cd $(dir $(BACKUP_DIR)) && zip -r $(BACKUP_ZIP) $(notdir $(BACKUP_DIR))/
	@echo "Cleaning up temporary files..."
	rm -r $(BACKUP_DIR)/
	@echo "Backup completed successfully! File saved to: $(BACKUP_ZIP)"

# Main restore target
restore:
	@echo "Starting restore process..."
	
	@# Check if the backup directory exists
	@if [ ! -f ./mysql_dump.sql ] || [ ! -f ./docker-compose.yml ]; then \
		echo "Error: Required backup files not found in current directory."; \
		echo "Please ensure you've unzipped the backup and are running this command from the backup directory."; \
		exit 1; \
	fi
	
	@echo "Reading environment variables..."
	@# Extract database variables from .env file if it exists
	@if [ -f ./.env ]; then \
		export $$(cat .env | grep -v ^# | xargs); \
	else \
		echo "Warning: .env file not found. Will use default values."; \
	fi
	
	@echo "Starting Docker containers..."
	docker-compose up -d
	
	@echo "Waiting for MySQL to be ready..."
	@sleep 10
	
	@echo "Available containers:"
	@docker ps
	@echo ""
	@echo "Enter the MySQL container ID from the list above:"
	@read -p "Container ID: " container_id && \
	echo "Using MySQL container: $$container_id" && \
	echo "" && \
	echo "Checking docker-compose.yml for WordPress port..." && \
	suggested_port=$$(grep -A10 "wordpress:" docker-compose.yml | grep -o ":[0-9]*->80" | grep -o "[0-9]*" | head -1 || echo 8000) && \
	echo "Suggested WordPress port from docker-compose.yml: $$suggested_port" && \
	echo "Enter the WordPress port (press Enter to use the suggested port):" && \
	read -p "WordPress Port: " wp_port && \
	if [ -z "$$wp_port" ]; then \
		wp_port=$$suggested_port; \
		echo "Using suggested port: $$wp_port"; \
	else \
		echo "Using custom port: $$wp_port"; \
	fi && \
	echo "" && \
	echo "Restoring database..." && \
	cat ./mysql_dump.sql | docker exec -i $$container_id mysql -u $(MYSQL_ROOT_USER) -p"$(MYSQL_ROOT_PASSWORD)" $(MYSQL_DATABASE) && \
	echo "Ensuring WordPress database user exists..." && \
	docker exec -i $$container_id mysql -u $(MYSQL_ROOT_USER) -p"$(MYSQL_ROOT_PASSWORD)" -e "CREATE USER IF NOT EXISTS '$(WP_DB_USER)'@'%' IDENTIFIED BY '$(WP_DB_USER_PASSWORD)';" && \
	docker exec -i $$container_id mysql -u $(MYSQL_ROOT_USER) -p"$(MYSQL_ROOT_PASSWORD)" -e "GRANT ALL PRIVILEGES ON $(MYSQL_DATABASE).* TO '$(WP_DB_USER)'@'%';" && \
	docker exec -i $$container_id mysql -u $(MYSQL_ROOT_USER) -p"$(MYSQL_ROOT_PASSWORD)" -e "FLUSH PRIVILEGES;" && \
	echo "Updating WordPress configuration..." && \
	if [ -f ./wordpress/wp-config.php ]; then \
		sed -i.bak "s/define( 'DB_HOST'.*/define( 'DB_HOST', '$(WORDPRESS_DB_HOST)' );/g" ./wordpress/wp-config.php && \
		sed -i.bak "s/define( 'DB_NAME'.*/define( 'DB_NAME', '$(MYSQL_DATABASE)' );/g" ./wordpress/wp-config.php && \
		sed -i.bak "s/define( 'DB_USER'.*/define( 'DB_USER', '$(WP_DB_USER)' );/g" ./wordpress/wp-config.php && \
		sed -i.bak "s/define( 'DB_PASSWORD'.*/define( 'DB_PASSWORD', '$(WP_DB_USER_PASSWORD)' );/g" ./wordpress/wp-config.php && \
		sed -i.bak "s|define('WP_HOME'.*|define('WP_HOME', 'http://localhost:$$wp_port');|g" ./wordpress/wp-config.php && \
		sed -i.bak "s|define('WP_SITEURL'.*|define('WP_SITEURL', 'http://localhost:$$wp_port');|g" ./wordpress/wp-config.php && \
		rm -f ./wordpress/wp-config.php.bak && \
		echo "WordPress configuration updated successfully!"; \
	else \
		echo "Warning: WordPress configuration file not found at ./wordpress/wp-config.php"; \
	fi && \
	echo "" && \
	echo "WordPress site restored successfully!" && \
	echo "" && \
	echo "IMPORTANT: If your site is not working correctly, you may need to check:" && \
	echo "  - Docker container status: docker ps" && \
	echo "  - Database connection settings in wp-config.php" && \
	echo "  - WordPress URL configuration in wp-config.php" && \
	echo "" && \
	echo "Your site should now be accessible at: http://localhost:$$wp_port"
