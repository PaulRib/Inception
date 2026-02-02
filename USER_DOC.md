# Inception - User Documentation

This document provides clear instructions for end users and administrators on how to use and manage the Inception infrastructure.

## Table of Contents

1. [Services Overview](#services-overview)
2. [Starting and Stopping the Project](#starting-and-stopping-the-project)
3. [Accessing the Website](#accessing-the-website)
4. [Managing Credentials](#managing-credentials)
5. [Checking Service Status](#checking-service-status)
6. [Common Tasks](#common-tasks)
7. [Troubleshooting](#troubleshooting)

---

## Services Overview

The Inception stack provides the following services:

### NGINX Web Server
- **Purpose**: Serves as the entry point for all web traffic
- **Features**: 
  - HTTPS-only access (TLSv1.2/TLSv1.3)
  - Reverse proxy to WordPress
  - Static file serving
- **Port**: 443 (HTTPS)

### WordPress + PHP-FPM
- **Purpose**: Content Management System for the website
- **Features**:
  - Full WordPress installation
  - User management
  - Content creation and editing
  - Plugin and theme support
- **Access**: Via NGINX on port 443

### MariaDB Database
- **Purpose**: Stores all website data
- **Features**:
  - WordPress database
  - User authentication data
  - Posts, pages, and settings
- **Access**: Internal only (not exposed to host)

### Service Communication
```
Internet → NGINX (443) → WordPress (9000) → MariaDB (3306)
```

---

## Starting and Stopping the Project

### Prerequisites
- Ensure your user has been added to the `docker` group, or use `sudo`
- Verify that ports 443 is available on your system

### Starting the Services

**Method 1: Using Make (Recommended)**
```bash
# Navigate to the project root directory
cd /path/to/inception

# Start all services
make
```

**Method 2: Using Docker Compose directly**
```bash
# Navigate to the srcs directory
cd /path/to/inception/srcs

# Build and start services in detached mode
docker compose up -d --build
```

**What happens during startup:**
1. Docker builds each container image (if not already built)
2. MariaDB starts and initializes the database
3. WordPress waits for MariaDB to be ready
4. WordPress installs and configures itself
5. NGINX starts and begins serving requests

**Expected output:**
```
[+] Building 45.2s (24/24) FINISHED
[+] Running 4/4
 ✔ Network inception      Created
 ✔ Container mariadb      Started
 ✔ Container wordpress    Started
 ✔ Container nginx        Started
```

### Stopping the Services

**Graceful shutdown (preserves data):**
```bash
# Using Make
make down

# Or using Docker Compose
docker compose down
```

**Force stop (if containers are unresponsive):**
```bash
docker compose kill
```

### Restarting a Specific Service

```bash
# Restart WordPress only
docker compose restart wp

# Restart NGINX only
docker compose restart nginx

# Restart MariaDB (will briefly interrupt the site)
docker compose restart db
```

---

## Accessing the Website

### Domain Configuration

**First-time setup:**
1. Add the domain to your hosts file:
   ```bash
   sudo nano /etc/hosts
   ```

2. Add this line:
   ```
   127.0.0.1 pribolzi.42.fr
   ```

3. Save and close (Ctrl+X, then Y, then Enter)

### Website Access

- **Main website**: https://pribolzi.42.fr
- **Admin panel**: https://pribolzi.42.fr/wp-admin

**Note**: You will see a security warning because the SSL certificate is self-signed. This is normal for development environments.

**To bypass the warning:**
- **Chrome/Edge**: Click "Advanced" → "Proceed to pribolzi.42.fr (unsafe)"
- **Firefox**: Click "Advanced" → "Accept the Risk and Continue"
- **Safari**: Click "Show Details" → "visit this website"

### First Visit

When you first access the site, you should see:
1. The WordPress homepage (if using default theme)
2. Ability to log in via the admin panel
3. Full HTTPS encryption (padlock icon with warning)

---

## Managing Credentials

### Credential Storage

All credentials are stored in the `.env` file located at:
```
srcs/requirements/.env
```

**⚠️ Security Note**: This file contains sensitive information and should NEVER be committed to version control.

### Viewing Credentials

```bash
# Display all credentials (be cautious where you run this)
cat srcs/requirements/.env

# Search for specific credentials
grep "WP_ADMIN_PASSWORD" srcs/requirements/.env
```

### Credential Types

#### WordPress Administrator Account
- **Username**: Defined in `WP_ADMIN_USER`
- **Password**: Defined in `WP_ADMIN_PASSWORD`
- **Email**: Defined in `WP_ADMIN_EMAIL`
- **Access**: https://pribolzi.42.fr/wp-admin

#### WordPress Editor Account
- **Username**: Defined in `WP_USER`
- **Password**: Defined in `WP_USER_PASSWORD`
- **Email**: Defined in `WP_USER_EMAIL`
- **Role**: Author (can create and publish posts)

#### Database Credentials
- **Database Name**: `SQL_DATABASE`
- **User**: `SQL_USER`
- **Password**: `SQL_PASSWORD`
- **Root Password**: `SQL_ROOT_PASSWORD`

### Changing Credentials

**⚠️ Warning**: Changing credentials after initial setup requires rebuilding containers.

1. **Stop the services:**
   ```bash
   make down
   ```

2. **Edit the `.env` file:**
   ```bash
   nano srcs/requirements/.env
   ```

3. **Clean existing data (DESTROYS ALL DATA):**
   ```bash
   make fclean
   ```

4. **Recreate data directories:**
   ```bash
   sudo mkdir -p /home/pribolzi/data/wp
   sudo mkdir -p /home/pribolzi/data/db
   ```

5. **Restart services:**
   ```bash
   make
   ```

### Password Reset (WordPress)

If you forget the WordPress admin password but have database access:

```bash
# Access MariaDB container
docker exec -it mariadb mysql -u root -p

# Enter the root password from .env file
# Then run:
USE wordpress;
UPDATE wp_users SET user_pass=MD5('new_password') WHERE user_login='admin';
EXIT;
```

---

## Checking Service Status

### Verify All Containers Are Running

```bash
docker ps

# Expected output shows 3 running containers:
# CONTAINER ID   IMAGE          ... STATUS         PORTS                   NAMES
# xxxxxxxxxxxx   nginx          ... Up 5 minutes   0.0.0.0:443->443/tcp    nginx
# xxxxxxxxxxxx   wordpress      ... Up 5 minutes   9000/tcp                wordpress
# xxxxxxxxxxxx   mariadb        ... Up 5 minutes   3306/tcp                mariadb
```

### Check Container Logs

```bash
# View all logs from all services
docker compose logs

# View logs from specific service
docker compose logs nginx
docker compose logs wordpress
docker compose logs db

# Follow logs in real-time
docker compose logs -f

# View last 50 lines
docker compose logs --tail=50
```

### Test Website Availability

```bash
# Test HTTPS connection
curl -k https://pribolzi.42.fr

# You should see HTML output containing WordPress content
```

### Check Database Connectivity

```bash
# From host machine
docker exec -it mariadb mysql -u wpuser -p

# Enter SQL_PASSWORD when prompted
# If successful, you'll see the MariaDB prompt:
# MariaDB [(none)]>

# Test database:
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
EXIT;
```

### Verify Network Communication

```bash
# Check that containers can communicate
docker exec wordpress ping -c 3 mariadb

# Should show successful pings
```

### Check Volume Mounts

```bash
# Verify WordPress files are present
ls -la /home/pribolzi/data/wp

# Verify database files are present
ls -la /home/pribolzi/data/db

# Check volume status
docker volume ls
docker volume inspect srcs_wp
docker volume inspect srcs_db
```

### Resource Usage

```bash
# Check container resource usage
docker stats

# Shows real-time CPU, memory, and network usage for each container
```

---

## Common Tasks

### Backup Website Data

```bash
# Create backup directory
mkdir -p ~/backups/inception_$(date +%Y%m%d)

# Backup WordPress files
sudo cp -r /home/pribolzi/data/wp ~/backups/inception_$(date +%Y%m%d)/

# Backup database
docker exec mariadb mysqldump -u root -p${SQL_ROOT_PASSWORD} wordpress > ~/backups/inception_$(date +%Y%m%d)/database.sql
```

### Restore from Backup

```bash
# Stop services
make down

# Restore WordPress files
sudo rm -rf /home/pribolzi/data/wp/*
sudo cp -r ~/backups/inception_YYYYMMDD/wp/* /home/pribolzi/data/wp/

# Start services
make

# Restore database
docker exec -i mariadb mysql -u root -p${SQL_ROOT_PASSWORD} wordpress < ~/backups/inception_YYYYMMDD/database.sql
```

### Install WordPress Plugins/Themes

**Method 1: Via Admin Panel (Recommended)**
1. Log in to https://pribolzi.42.fr/wp-admin
2. Navigate to Plugins → Add New or Appearance → Themes
3. Search and install desired plugins/themes

**Method 2: Via WP-CLI**
```bash
# Access WordPress container
docker exec -it wordpress bash

# Install a plugin
wp plugin install <plugin-name> --activate --allow-root

# Install a theme
wp theme install <theme-name> --activate --allow-root

# Exit container
exit
```

### Update WordPress Core

```bash
# Access WordPress container
docker exec -it wordpress bash

# Check for updates
wp core check-update --allow-root

# Update WordPress
wp core update --allow-root

# Exit container
exit
```

---

## Troubleshooting

### Website Not Accessible

**Problem**: Cannot access https://pribolzi.42.fr

**Solutions**:
1. Verify containers are running:
   ```bash
   docker ps
   ```

2. Check hosts file:
   ```bash
   grep pribolzi /etc/hosts
   ```

3. Verify port 443 is listening:
   ```bash
   sudo netstat -tulpn | grep 443
   ```

4. Check NGINX logs:
   ```bash
   docker compose logs nginx
   ```

### Database Connection Errors

**Problem**: WordPress shows "Error establishing database connection"

**Solutions**:
1. Verify MariaDB is running:
   ```bash
   docker ps | grep mariadb
   ```

2. Check MariaDB logs:
   ```bash
   docker compose logs db
   ```

3. Verify environment variables:
   ```bash
   docker exec wordpress env | grep SQL
   ```

4. Test database connection:
   ```bash
   docker exec wordpress mysqladmin -h mariadb -u wpuser -p${SQL_PASSWORD} ping
   ```

### Container Keeps Restarting

**Problem**: A container continuously restarts

**Solutions**:
1. Check container logs for errors:
   ```bash
   docker compose logs <service-name>
   ```

2. View last restart reason:
   ```bash
   docker inspect <container-name> | grep -A 10 "State"
   ```

3. Try running container manually:
   ```bash
   docker compose up <service-name>
   ```

### Permission Denied Errors

**Problem**: Permission errors in logs

**Solutions**:
```bash
# Fix WordPress directory permissions
sudo chown -R www-data:www-data /home/pribolzi/data/wp

# Fix database directory permissions
sudo chown -R 999:999 /home/pribolzi/data/db
```

### SSL Certificate Warnings

**Problem**: Browser shows "Your connection is not private"

**Explanation**: This is normal for self-signed certificates. For production, use Let's Encrypt.

**To proceed**: Click "Advanced" and accept the risk.

### Out of Disk Space

**Problem**: Containers fail due to disk space

**Solutions**:
```bash
# Check disk usage
df -h

# Remove unused Docker resources
docker system prune -a

# Warning: This removes all unused containers, networks, and images
```

---

## Support

For additional help:
1. Check container logs: `docker compose logs`
2. Review the [README.md](README.md) for architecture details
3. Consult the [DEV_DOC.md](DEV_DOC.md) for technical information
4. Search the Docker documentation: https://docs.docker.com/

---

## Quick Reference Commands

| Task | Command |
|------|---------|
| Start services | `make` |
| Stop services | `make down` |
| View logs | `docker compose logs` |
| Access WordPress container | `docker exec -it wordpress bash` |
| Access MariaDB CLI | `docker exec -it mariadb mysql -u root -p` |
| Restart a service | `docker compose restart <service>` |
| Check container status | `docker ps` |
| View resource usage | `docker stats` |
