# Makefile for WordPress Backup and Restore
# Date: $(shell date +%d/%m/%Y)

# Variables
BACKUP_DATE := $(shell date +%d_%m_%Y)
BACKUP_DIR := ~/Downloads/temp/site_backup_$(BACKUP_DATE)
BACKUP_ZIP := $(BACKUP_DIR).zip
MYSQL_CONTAINER_ID := $(shell docker ps -qf "name=mysql")
MYSQL_ROOT_USER := root
MYSQL_ROOT_PASSWORD := $(shell grep MYSQL_ROOT_PASSWORD .env | cut -d '=' -f2)
MYSQL_DATABASE := $(shell grep MYSQL_DATABASE .env | cut -d '=' -f2)

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
	mkdir -p $(BACKUP_DIR)
	@echo "Creating MySQL dump..."
	docker exec $(MYSQL_CONTAINER_ID) mysqldump -u $(MYSQL_ROOT_USER) -p"$(MYSQL_ROOT_PASSWORD)" $(MYSQL_DATABASE) > $(BACKUP_DIR)/mysql_dump.sql
	@echo "Copying WordPress files..."
	cp -r ./wordpress $(BACKUP_DIR)/wordpress
	@echo "Copying configuration files..."
	cp docker-compose.yml $(BACKUP_DIR)/
	cp .env $(BACKUP_DIR)/
	cp backup_steps.md $(BACKUP_DIR)/ 2>/dev/null || true
	cp secrets.txt $(BACKUP_DIR)/ 2>/dev/null || true
	@echo "Creating ZIP archive..."
	zip -r $(BACKUP_ZIP) $(BACKUP_DIR)/
	@echo "Cleaning up temporary files..."
	rm -r $(BACKUP_DIR)/
	@echo "Backup completed successfully! File saved to: $(BACKUP_ZIP)"

# Restore target
restore:
	@echo "Starting restore process..."
	@if [ ! -d ~/Downloads/site_backup_$(BACKUP_DATE) ]; then \
		echo "Error: Backup directory not found. Please unzip the backup file first."; \
		exit 1; \
	fi
	@echo "Stopping Docker containers..."
	docker-compose down
	@echo "Copying WordPress files..."
	cp -r ~/Downloads/site_backup_$(BACKUP_DATE)/wordpress ./
	@echo "Starting Docker containers..."
	docker-compose up -d
	@echo "Restoring database..."
	cat ~/Downloads/site_backup_$(BACKUP_DATE)/mysql_dump.sql | docker exec -i $(MYSQL_CONTAINER_ID) mysql -u $(MYSQL_ROOT_USER) -p"$(MYSQL_ROOT_PASSWORD)"
	@echo "Restore completed successfully!"

# Clean target
clean:
	@echo "Cleaning up backup directories..."
	rm -rf ~/Downloads/site_backup_*/ 2>/dev/null || true
	@echo "Cleanup completed."