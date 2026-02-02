# Inception - Developer Documentation

This document provides detailed technical information for developers who want to set up, modify, or extend the Inception project.

## Table of Contents

1. [Environment Setup from Scratch](#environment-setup-from-scratch)
2. [Project Structure](#project-structure)
3. [Building and Launching](#building-and-launching)
4. [Container Management](#container-management)
5. [Volume and Data Management](#volume-and-data-management)
6. [Configuration Files](#configuration-files)
7. [Development Workflow](#development-workflow)
8. [Debugging Techniques](#debugging-techniques)
9. [Extending the Project](#extending-the-project)

---

## Environment Setup from Scratch

### System Requirements

- **Operating System**: Linux (Debian/Ubuntu recommended)
- **RAM**: Minimum 2GB, 4GB recommended
- **Disk Space**: At least 10GB free
- **Processor**: x86_64 architecture

### Installing Prerequisites

#### 1. Install Docker Engine

```bash
# Update package index
sudo apt-get update

# Install required packages
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Verify installation
docker --version
```

#### 2. Configure Docker Permissions

```bash
# Add your user to the docker group
sudo usermod -aG docker $USER

# Log out and log back in for changes to take effect
# Or run:
newgrp docker

# Verify you can run Docker without sudo
docker ps
```

#### 3. Install Make

```bash
sudo apt-get install -y make

# Verify installation
make --version
```

### Project Setup

#### 1. Clone the Repository

```bash
git clone <repository-url>
cd inception
```

#### 2. Create Configuration Files

**Create the environment file:**
```bash
mkdir -p srcs/requirements
nano srcs/requirements/.env
```

**Add the following content** (adjust values as needed):
```bash
# Database Configuration
SQL_DATABASE=wordpress
SQL_USER=wpuser
SQL_PASSWORD=secure_db_password_here
SQL_ROOT_PASSWORD=secure_root_password_here
SQL_HOST=mariadb

# WordPress Configuration
WP_URL=https://pribolzi.42.fr
WP_TITLE=My Inception Site
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=secure_admin_password
WP_ADMIN_EMAIL=admin@example.com
WP_USER=editor
WP_USER_EMAIL=editor@example.com
WP_USER_PASSWORD=secure_editor_password
```

**⚠️ Important**: Replace all password placeholders with strong, unique passwords.

#### 3. Create Data Directories

```bash
# Create data directories with appropriate permissions
sudo mkdir -p /home/$(whoami)/data/wp
sudo mkdir -p /home/$(whoami)/data/db

# Set proper ownership
sudo chown -R $USER:$USER /home/$(whoami)/data
```

**Note**: If using a different username, update the paths in `docker-compose.yml`:
```yaml
volumes:
  wp:
    driver_opts:
      device: '/home/YOUR_USERNAME/data/wp'
  db:
    driver_opts:
      device: '/home/YOUR_USERNAME/data/db'
```

#### 4. Generate SSL Certificates

The NGINX Dockerfile should generate self-signed certificates automatically. If you need to generate them manually:

```bash
# Create certificate directory
mkdir -p srcs/requirements/nginx/certs

# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout srcs/requirements/nginx/certs/nginx.key \
  -out srcs/requirements/nginx/certs/nginx.crt \
  -subj "/C=FR/ST=France/L=Paris/O=42/OU=42/CN=pribolzi.42.fr"
```

#### 5. Configure Domain Resolution

```bash
# Add domain to hosts file
echo "127.0.0.1 pribolzi.42.fr" | sudo tee -a /etc/hosts
```

---

## Project Structure

### Directory Layout

```
inception/
├── Makefile                          # Build and management commands
├── README.md                         # Project overview and documentation
├── USER_DOC.md                       # End-user documentation
├── DEV_DOC.md                        # Developer documentation (this file)
└── srcs/
    ├── docker-compose.yml            # Service orchestration configuration
    └── requirements/
        ├── .env                      # Environment variables (gitignored)
        ├── mariadb/
        │   ├── Dockerfile            # MariaDB container definition
        │   └── init_db.sh            # Database initialization script
        ├── wordpress/
        │   ├── Dockerfile            # WordPress + PHP-FPM container
        │   └── init_wordpress.sh     # WordPress setup and configuration
        └── nginx/
            ├── Dockerfile            # NGINX container definition
            └── default.conf          # NGINX server configuration
```

### Key Files Explained

#### `docker-compose.yml`
- Orchestrates three services: `db`, `wp`, and `nginx`
- Defines the `inception` bridge network
- Configures volume mounts for data persistence
- Sets service dependencies and restart policies

#### Dockerfiles
- Each service has its own Dockerfile building from `debian:bullseye`
- No use of pre-built images (except base Debian)
- Services are configured during image build

#### Initialization Scripts
- `init_db.sh`: Sets up MariaDB, creates database and users
- `init_wordpress.sh`: Installs WordPress via WP-CLI, configures database connection

---

## Building and Launching

### Using the Makefile

The Makefile provides convenient commands for common operations:

```bash
# View available commands
make help

# Build and start all services
make

# Equivalent to:
make all
```

### Makefile Commands

| Command | Description |
|---------|-------------|
| `make` or `make all` | Build images and start containers |
| `make build` | Build Docker images without starting |
| `make up` | Start containers (must be built first) |
| `make down` | Stop containers, remove networks |
| `make stop` | Stop containers without removing them |
| `make start` | Start stopped containers |
| `make clean` | Stop containers, remove volumes |
| `make fclean` | Complete cleanup including data dirs |
| `make re` | Clean rebuild (fclean + all) |
| `make logs` | View logs from all services |
| `make ps` | List running containers |

### Manual Docker Compose Commands

If you prefer direct control:

```bash
# Navigate to srcs directory
cd srcs

# Build images
docker compose build

# Start services in detached mode
docker compose up -d

# Start services with build
docker compose up -d --build

# Stop services
docker compose down

# Stop and remove volumes
docker compose down -v

# View logs
docker compose logs

# Follow logs in real-time
docker compose logs -f

# Rebuild a specific service
docker compose build mariadb
docker compose up -d --no-deps mariadb
```

### Build Process Details

#### Build Order
Due to dependencies defined in `docker-compose.yml`:
1. **MariaDB** builds first (no dependencies)
2. **WordPress** builds next (depends on `db`)
3. **NGINX** builds last (depends on `wp`)

#### Build Context
Each service uses its respective directory as build context:
- MariaDB: `./requirements/mariadb`
- WordPress: `./requirements/wordpress`
- NGINX: `./requirements/nginx`

#### Environment Variables
- Loaded from `./requirements/.env`
- Available to all services during runtime
- Not baked into images (for security)

### Startup Sequence

1. **MariaDB container starts**
   - `init_db.sh` creates socket directory
   - Initializes database system files if needed
   - Creates WordPress database and user
   - Sets root password
   - Starts `mysqld_safe`

2. **WordPress container starts**
   - Waits for MariaDB to be ready (ping loop)
   - Downloads WP-CLI if not present
   - Downloads WordPress core files
   - Creates `wp-config.php`
   - Installs WordPress
   - Creates additional user
   - Starts PHP-FPM

3. **NGINX container starts**
   - Loads SSL certificates
   - Starts NGINX daemon
   - Proxies requests to WordPress

---

## Container Management

### Accessing Containers

```bash
# Execute bash shell in a container
docker exec -it mariadb bash
docker exec -it wordpress bash
docker exec -it nginx bash

# Run one-off commands
docker exec mariadb mysql --version
docker exec wordpress php --version
docker exec nginx nginx -v
```

### Inspecting Containers

```bash
# View detailed container information
docker inspect mariadb

# View container resource usage
docker stats

# View container processes
docker top mariadb

# View container networks
docker inspect mariadb | grep -A 20 NetworkSettings
```

### Restarting Services

```bash
# Restart a single service
docker compose restart db
docker compose restart wp
docker compose restart nginx

# Restart all services
docker compose restart

# Force recreation of a container
docker compose up -d --force-recreate wp
```

### Viewing Logs

```bash
# All services
docker compose logs

# Specific service
docker compose logs mariadb
docker compose logs wordpress
docker compose logs nginx

# Follow logs (live updates)
docker compose logs -f

# Last N lines
docker compose logs --tail=100 wordpress

# Logs with timestamps
docker compose logs -t

# Logs from specific time
docker compose logs --since 2024-01-30T10:00:00
```

### Container Health Checks

Although not explicitly defined in the compose file, you can check health:

```bash
# Check if WordPress can connect to database
docker exec wordpress mysqladmin -h mariadb -u wpuser -p$SQL_PASSWORD ping

# Check NGINX configuration
docker exec nginx nginx -t

# Check PHP-FPM status
docker exec wordpress php-fpm7.4 -t
```

---

## Volume and Data Management

### Volume Overview

The project uses bind mounts configured as Docker volumes:

```yaml
volumes:
  wp:
    driver: local
    driver_opts:
      type: 'none'
      o: 'bind'
      device: '/home/pribolzi/data/wp'
  db:
    driver: local
    driver_opts:
      type: 'none'
      o: 'bind'
      device: '/home/pribolzi/data/db'
```

### Data Locations

| Data Type | Container Path | Host Path |
|-----------|---------------|-----------|
| WordPress files | `/var/www/html` | `/home/pribolzi/data/wp` |
| MariaDB data | `/var/lib/mysql` | `/home/pribolzi/data/db` |

### Volume Commands

```bash
# List volumes
docker volume ls

# Inspect a volume
docker volume inspect srcs_wp
docker volume inspect srcs_db

# Check volume usage
du -sh /home/pribolzi/data/wp
du -sh /home/pribolzi/data/db
```

### Data Persistence

**What persists across container restarts:**
- WordPress core files, themes, plugins
- Uploaded media (images, documents)
- Database tables and data
- User accounts and settings
- WordPress configuration

**What does NOT persist:**
- Running container state
- Container logs (unless configured)
- Processes and temporary files in `/tmp`

### Backup Procedures

#### Manual Backup

```bash
# Create backup directory
mkdir -p ~/backups/inception_$(date +%Y%m%d_%H%M%S)

# Backup WordPress files (preserves permissions)
sudo rsync -av /home/pribolzi/data/wp/ ~/backups/inception_$(date +%Y%m%d_%H%M%S)/wp/

# Backup database files
sudo rsync -av /home/pribolzi/data/db/ ~/backups/inception_$(date +%Y%m%d_%H%M%S)/db/

# Database SQL dump (alternative)
docker exec mariadb mysqldump -u root -p${SQL_ROOT_PASSWORD} wordpress > ~/backups/inception_$(date +%Y%m%d_%H%M%S)/wordpress.sql
```

#### Automated Backup Script

Create `backup.sh`:
```bash
#!/bin/bash

BACKUP_DIR="$HOME/backups/inception"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/$DATE"

mkdir -p "$BACKUP_PATH"

# WordPress files
sudo rsync -av /home/pribolzi/data/wp/ "$BACKUP_PATH/wp/"

# Database dump
docker exec mariadb mysqldump -u root -p${SQL_ROOT_PASSWORD} wordpress > "$BACKUP_PATH/wordpress.sql"

# Compress
tar -czf "$BACKUP_PATH.tar.gz" -C "$BACKUP_DIR" "$DATE"
rm -rf "$BACKUP_PATH"

# Keep only last 7 backups
ls -t "$BACKUP_DIR"/*.tar.gz | tail -n +8 | xargs -r rm

echo "Backup completed: $BACKUP_PATH.tar.gz"
```

### Data Cleanup

```bash
# WARNING: These commands PERMANENTLY DELETE DATA

# Remove all data (requires fclean or manual deletion)
sudo rm -rf /home/pribolzi/data/wp/*
sudo rm -rf /home/pribolzi/data/db/*

# Using Makefile
make fclean  # Removes containers, volumes, and data directories
```

---

## Configuration Files

### docker-compose.yml

**Key sections:**

```yaml
services:
  db:
    build: ./requirements/mariadb   # Build context
    container_name: mariadb         # Fixed container name
    restart: always                 # Auto-restart on failure
    env_file: ./requirements/.env   # Load environment variables
    networks: [inception]           # Custom bridge network
    volumes: [db:/var/lib/mysql]    # Persistent storage
    expose: ["3306"]                # Internal port (not published)
```

**Important fields:**
- `restart: always` - Ensures containers restart after system reboot
- `expose` - Makes ports available to other containers (not to host)
- `ports` - Publishes ports to host (only NGINX uses this)
- `depends_on` - Controls startup order (not readiness)

### Environment Variables (.env)

**Database variables:**
- `SQL_DATABASE`: Database name for WordPress
- `SQL_USER`: Database user for WordPress
- `SQL_PASSWORD`: Password for `SQL_USER`
- `SQL_ROOT_PASSWORD`: MariaDB root password
- `SQL_HOST`: Database hostname (container name: `mariadb`)

**WordPress variables:**
- `WP_URL`: Site URL with protocol
- `WP_TITLE`: Site title
- `WP_ADMIN_USER`: Admin username
- `WP_ADMIN_PASSWORD`: Admin password
- `WP_ADMIN_EMAIL`: Admin email
- `WP_USER`: Additional user username
- `WP_USER_EMAIL`: Additional user email
- `WP_USER_PASSWORD`: Additional user password

**Usage in scripts:**
```bash
# Variables are automatically available in containers
echo $SQL_DATABASE
```

### NGINX Configuration (default.conf)

**SSL/TLS configuration:**
```nginx
listen 443 ssl;                           # HTTPS only
ssl_protocols TLSv1.2 TLSv1.3;           # Modern protocols only
ssl_certificate /etc/ssl/certs/nginx.crt;
ssl_certificate_key /etc/ssl/private/nginx.key;
```

**PHP-FPM proxy:**
```nginx
location ~ \.php$ {
    fastcgi_pass wordpress:9000;          # Proxy to WordPress container
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
}
```

**Important notes:**
- No HTTP (port 80) listener - HTTPS only
- `fastcgi_pass wordpress:9000` uses Docker network service discovery
- Static files served directly by NGINX
- PHP files proxied to PHP-FPM in WordPress container

### MariaDB Configuration

**Modified in Dockerfile:**
```dockerfile
RUN sed -i "s|bind-address = 127.0.0.1|bind-address = 0.0.0.0|g" \
    "/etc/mysql/mariadb.conf.d/50-server.cnf"
```

This allows connections from other containers (WordPress).

**Security considerations:**
- Only accessible within Docker network (port 3306 not published)
- Strong passwords required
- Root login restricted to localhost

---

## Development Workflow

### Making Changes to Services

#### Modifying NGINX Configuration

1. Edit `srcs/requirements/nginx/default.conf`
2. Rebuild and restart:
   ```bash
   docker compose build nginx
   docker compose up -d --no-deps nginx
   ```
3. Test configuration:
   ```bash
   docker exec nginx nginx -t
   ```

#### Modifying WordPress/PHP Settings

1. Edit `srcs/requirements/wordpress/Dockerfile` or `init_wordpress.sh`
2. Rebuild:
   ```bash
   docker compose build wp
   ```
3. Stop and remove old container:
   ```bash
   docker compose down
   ```
4. Start fresh:
   ```bash
   docker compose up -d
   ```

#### Modifying Database Configuration

1. Edit `srcs/requirements/mariadb/Dockerfile` or `init_db.sh`
2. **Warning**: Database changes may require data reset
3. Backup first:
   ```bash
   docker exec mariadb mysqldump -u root -p${SQL_ROOT_PASSWORD} wordpress > backup.sql
   ```
4. Rebuild:
   ```bash
   make fclean
   make
   ```

### Testing Changes

```bash
# Test NGINX configuration syntax
docker exec nginx nginx -t

# Test PHP syntax
docker exec wordpress php -l /var/www/html/index.php

# Test database connection
docker exec wordpress mysqladmin -h mariadb -u wpuser -p${SQL_PASSWORD} ping

# Test website response
curl -k https://pribolzi.42.fr
```

### Debugging Container Issues

**Container won't start:**
```bash
# View build output
docker compose build --no-cache mariadb

# View startup logs
docker compose up mariadb

# Check for port conflicts
sudo netstat -tulpn | grep -E ':(443|9000|3306)'
```

**Container exits immediately:**
```bash
# View last logs
docker compose logs --tail=50 mariadb

# Inspect exit code
docker inspect mariadb | grep -A 5 "State"

# Run container interactively
docker compose run --rm mariadb bash
```

### Development Best Practices

1. **Always test in a clean environment:**
   ```bash
   make fclean
   make
   ```

2. **Use `.dockerignore` to exclude files:**
   ```
   .git
   .env
   *.md
   ```

3. **Tag images for version control:**
   ```bash
   docker tag srcs-nginx:latest srcs-nginx:v1.0
   ```

4. **Use `--no-cache` for clean builds:**
   ```bash
   docker compose build --no-cache
   ```

---

## Debugging Techniques

### Network Debugging

```bash
# View network details
docker network inspect srcs_inception

# Test connectivity between containers
docker exec wordpress ping -c 3 mariadb
docker exec nginx ping -c 3 wordpress

# Check open ports inside container
docker exec mariadb netstat -tulpn
docker exec wordpress netstat -tulpn

# DNS resolution test
docker exec wordpress nslookup mariadb
```

### File System Debugging

```bash
# Check file permissions
docker exec wordpress ls -la /var/www/html
docker exec mariadb ls -la /var/lib/mysql

# View file contents
docker exec wordpress cat /var/www/html/wp-config.php
docker exec nginx cat /etc/nginx/conf.d/default.conf

# Check disk usage
docker exec wordpress df -h
```

### Process Debugging

```bash
# View running processes
docker exec mariadb ps aux
docker exec wordpress ps aux | grep php
docker exec nginx ps aux | grep nginx

# Check listening ports
docker exec nginx ss -tulpn | grep LISTEN
```

### Database Debugging

```bash
# Access MariaDB CLI
docker exec -it mariadb mysql -u root -p

# Useful SQL commands:
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
SELECT * FROM wp_users;
SHOW PROCESSLIST;
SHOW VARIABLES LIKE 'bind_address';
```

### WordPress Debugging

```bash
# Enable WordPress debug mode
docker exec wordpress wp config set WP_DEBUG true --allow-root

# Check WordPress status
docker exec wordpress wp core verify-checksums --allow-root

# List plugins
docker exec wordpress wp plugin list --allow-root

# List users
docker exec wordpress wp user list --allow-root
```

### SSL/TLS Debugging

```bash
# Test SSL certificate
openssl s_client -connect pribolzi.42.fr:443 -showcerts

# Check certificate details
docker exec nginx openssl x509 -in /etc/ssl/certs/nginx.crt -text -noout
```

### Common Issues and Solutions

**Issue**: "Error establishing database connection"
```bash
# Solution 1: Check database is running
docker ps | grep mariadb

# Solution 2: Verify credentials
docker exec wordpress env | grep SQL

# Solution 3: Test connection
docker exec wordpress mysqladmin -h mariadb -u wpuser -p${SQL_PASSWORD} ping
```

**Issue**: "502 Bad Gateway"
```bash
# Solution: Check WordPress/PHP-FPM is running
docker exec wordpress ps aux | grep php-fpm

# Check NGINX can reach WordPress
docker exec nginx curl wordpress:9000
```

**Issue**: Volume permission errors
```bash
# Solution: Fix ownership
sudo chown -R www-data:www-data /home/pribolzi/data/wp
sudo chown -R 999:999 /home/pribolzi/data/db
```

---

## Extending the Project

### Adding New Services

1. **Create service directory:**
   ```bash
   mkdir -p srcs/requirements/newservice
   ```

2. **Create Dockerfile:**
   ```dockerfile
   FROM debian:bullseye
   
   RUN apt-get update && apt-get install -y service-package
   
   COPY config.conf /etc/service/
   
   EXPOSE 8080
   
   CMD ["service-daemon"]
   ```

3. **Add to docker-compose.yml:**
   ```yaml
   services:
     newservice:
       build: ./requirements/newservice
       container_name: newservice
       restart: always
       networks:
         - inception
       volumes:
         - newservice:/data
       expose:
         - "8080"
   ```

4. **Add volume if needed:**
   ```yaml
   volumes:
     newservice:
       driver: local
       driver_opts:
         type: 'none'
         o: 'bind'
         device: '/home/pribolzi/data/newservice'
   ```

### Implementing Bonus Features

**Example: Adding Redis cache**

1. Create `srcs/requirements/redis/Dockerfile`:
   ```dockerfile
   FROM debian:bullseye
   
   RUN apt-get update && apt-get install -y redis-server
   
   RUN sed -i "s/bind 127.0.0.1/bind 0.0.0.0/g" /etc/redis/redis.conf
   
   EXPOSE 6379
   
   CMD ["redis-server", "--protected-mode", "no"]
   ```

2. Add to docker-compose.yml and configure WordPress to use it

### Performance Optimization

```bash
# Build with BuildKit for better caching
DOCKER_BUILDKIT=1 docker compose build

# Use multi-stage builds in Dockerfiles
FROM debian:bullseye AS builder
# ... build steps ...

FROM debian:bullseye
COPY --from=builder /built/artifact /
```

### Security Hardening

1. **Use Docker secrets instead of environment variables**
2. **Implement least-privilege user policies**
3. **Regular security updates:**
   ```dockerfile
   RUN apt-get update && apt-get upgrade -y
   ```
4. **Use specific package versions**
5. **Implement proper firewall rules**

---

## Quick Reference

### Essential Commands

```bash
# Start project
make

# Stop project
make down

# Complete cleanup
make fclean

# View logs
docker compose logs -f

# Access container
docker exec -it <container> bash

# Rebuild service
docker compose build <service>
docker compose up -d --no-deps <service>
```

### File Locations

| Item | Path |
|------|------|
| Docker Compose | `srcs/docker-compose.yml` |
| Environment vars | `srcs/requirements/.env` |
| MariaDB init | `srcs/requirements/mariadb/init_db.sh` |
| WordPress init | `srcs/requirements/wordpress/init_wordpress.sh` |
| NGINX config | `srcs/requirements/nginx/default.conf` |
| WordPress data | `/home/pribolzi/data/wp` |
| Database data | `/home/pribolzi/data/db` |

---

## Additional Resources

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)
- [WordPress CLI Commands](https://developer.wordpress.org/cli/commands/)
- [MariaDB Documentation](https://mariadb.com/kb/en/)
- [NGINX Beginner's Guide](https://nginx.org/en/docs/beginners_guide.html)
