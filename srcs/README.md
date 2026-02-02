# Inception

*This project has been created as part of the 42 curriculum by pribolzi.*

## Description

Inception is a system administration project that focuses on containerization using Docker. The goal is to set up a small infrastructure composed of different services following specific rules. Each service runs in a dedicated Docker container, and the entire infrastructure is orchestrated using Docker Compose.

The project implements a complete LEMP stack (Linux, Nginx, MariaDB, PHP) hosting a WordPress website, with all services running in separate containers:
- **NGINX**: Web server with TLSv1.2/TLSv1.3 support
- **WordPress + PHP-FPM**: Content management system
- **MariaDB**: Database server

All services are built from Debian Bullseye base images (penultimate stable version at the time of project creation), and containers communicate through a dedicated Docker bridge network. The project emphasizes best practices in containerization, security (HTTPS only), and infrastructure automation.

## Instructions

### Prerequisites

- Docker Engine (version 20.10 or higher)
- Docker Compose (version 1.29 or higher)
- Make
- Linux environment (tested on Debian/Ubuntu)

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd inception
   ```

2. **Configure environment variables**
   
   Create a `.env` file in `srcs/requirements/` with the following variables:
   ```bash
   # Database Configuration
   SQL_DATABASE=wordpress
   SQL_USER=wpuser
   SQL_PASSWORD=your_secure_password
   SQL_ROOT_PASSWORD=your_root_password
   SQL_HOST=mariadb
   
   # WordPress Configuration
   WP_URL=https://pribolzi.42.fr
   WP_TITLE=Your Site Title
   WP_ADMIN_USER=admin
   WP_ADMIN_PASSWORD=admin_password
   WP_ADMIN_EMAIL=admin@example.com
   WP_USER=editor
   WP_USER_EMAIL=editor@example.com
   WP_USER_PASSWORD=editor_password
   ```

3. **Configure domain name**
   
   Add the following line to `/etc/hosts`:
   ```
   127.0.0.1 pribolzi.42.fr
   ```

4. **Create data directories**
   ```bash
   sudo mkdir -p /home/pribolzi/data/wp
   sudo mkdir -p /home/pribolzi/data/db
   ```

### Compilation and Execution

```bash
# Build and start all services
make

# Stop all services
make down

# Stop and remove all containers, networks, and volumes
make clean

# Complete cleanup including data directories
make fclean

# Rebuild everything from scratch
make re
```

### Access

- **Website**: https://pribolzi.42.fr
- **WordPress Admin Panel**: https://pribolzi.42.fr/wp-admin

## Project Architecture

### Docker Usage

This project leverages Docker containerization to create an isolated, reproducible infrastructure. Each service (NGINX, WordPress, MariaDB) runs in its own container with a dedicated Dockerfile, ensuring separation of concerns and easy scalability.

**Key design choices:**
- **Custom Dockerfiles**: All containers are built from scratch using Debian Bullseye, avoiding ready-made Docker images
- **Multi-stage separation**: Each service has its own build context in `requirements/<service>/`
- **Health checks**: Services wait for dependencies (e.g., WordPress waits for MariaDB to be ready)
- **Persistent storage**: Data persists across container restarts using Docker volumes with bind mounts

### Source Files Structure

```
srcs/
├── docker-compose.yml          # Orchestration configuration
└── requirements/
    ├── .env                    # Environment variables (not in repo)
    ├── mariadb/
    │   ├── Dockerfile          # MariaDB container definition
    │   └── init_db.sh          # Database initialization script
    ├── wordpress/
    │   ├── Dockerfile          # WordPress + PHP-FPM container
    │   └── init_wordpress.sh   # WordPress setup script
    └── nginx/
        ├── Dockerfile          # NGINX container definition
        └── default.conf        # NGINX SSL configuration
```

### Technical Comparisons

#### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker Containers |
|--------|-----------------|-------------------|
| **Resource Usage** | Heavy - each VM runs a full OS | Lightweight - shares host kernel |
| **Startup Time** | Minutes | Seconds |
| **Isolation** | Complete hardware virtualization | Process-level isolation |
| **Portability** | Limited - large image sizes | Excellent - small, portable images |
| **Use Case** | Running different OS, complete isolation | Microservices, development environments |

**Why Docker for this project**: Containers provide sufficient isolation for our services while maintaining efficiency. Each service (NGINX, WordPress, MariaDB) runs independently but shares the host kernel, reducing overhead.

#### Secrets vs Environment Variables

| Aspect | Secrets | Environment Variables |
|--------|---------|----------------------|
| **Storage** | Encrypted, managed by orchestrator | Plain text in containers |
| **Access** | Mounted as files, restricted permissions | Available in process environment |
| **Security** | High - encrypted at rest and in transit | Low - visible in container inspect |
| **Versioning** | Separate from code | Often committed to repos (risky) |

**Project choice**: This project uses environment variables (`.env` file) for simplicity and educational purposes. In production, Docker Swarm secrets or Kubernetes secrets would be preferable for sensitive data like database passwords.

#### Docker Network vs Host Network

| Aspect | Docker Network (bridge) | Host Network |
|--------|------------------------|--------------|
| **Isolation** | Containers have own network namespace | Container shares host network stack |
| **Port Management** | Port mapping required (e.g., 443:443) | Direct access to host ports |
| **Security** | Better - internal container IPs | Lower - exposes host network |
| **DNS** | Automatic service discovery by name | Manual IP management |
| **Performance** | Slight overhead from NAT | No overhead |

**Project choice**: Uses a custom bridge network (`inception`) for isolation and service discovery. Containers communicate using service names (e.g., `wordpress:9000`, `mariadb:3306`), while only NGINX port 443 is exposed to the host.

#### Docker Volumes vs Bind Mounts

| Aspect | Docker Volumes | Bind Mounts |
|--------|---------------|-------------|
| **Management** | Managed by Docker | Direct host path mapping |
| **Location** | Docker-managed location | Specified host directory |
| **Portability** | Better - abstracted from host | Lower - path-dependent |
| **Performance** | Optimized by Docker | Native filesystem performance |
| **Backup** | `docker volume` commands | Standard file backup tools |

**Project choice**: This project uses **bind mounts** configured as Docker volumes:
```yaml
volumes:
  wp:
    driver: local
    driver_opts:
      type: 'none'
      o: 'bind'
      device: '/home/pribolzi/data/wp'
```

This hybrid approach provides:
- Explicit control over data location (required by subject)
- Easy access for backups and debugging
- Persistence across container recreation
- The WordPress volume (`/var/www/html`) is shared between NGINX and WordPress containers

## Resources

### Official Documentation
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.com/kb/en/documentation/)
- [WordPress CLI Documentation](https://wp-cli.org/)

### Tutorials and Articles
- [Docker Networking Overview](https://docs.docker.com/network/)
- [Best practices for writing Dockerfiles](https://docs.docker.com/develop/dev-best-practices/)
- [WordPress with Docker](https://docs.docker.com/samples/wordpress/)
- [SSL/TLS Configuration for NGINX](https://ssl-config.mozilla.org/)

### AI Usage

AI assistance (Claude by Anthropic) was used for the following tasks:

1. **Shell Script Debugging**: Identifying and fixing issues in MariaDB initialization script (socket permissions, SQL execution flow)
2. **Docker Compose Syntax**: Validation of YAML syntax and best practices for service dependencies
3. **Configuration Optimization**: Reviewing NGINX SSL/TLS configuration and PHP-FPM settings

**Parts NOT assisted by AI**:
- All Dockerfile creation and service configuration
- Network architecture design
- Volume mount strategy
- WordPress and database initialization logic
- Security decisions (TLS versions, bind mounts location)

The AI was used as a documentation and debugging tool, not as a code generator. All implementation decisions and technical choices were made independently.

## Additional Information

### Security Considerations

- TLSv1.2 and TLSv1.3 only (no older protocols)
- Self-signed certificates (for development; use Let's Encrypt in production)
- Database accessible only within Docker network
- No sensitive data in Dockerfiles or repository

### Project Status

This project meets all mandatory requirements:
- ✅ Custom Dockerfiles from Debian Bullseye
- ✅ NGINX with TLSv1.2/TLSv1.3 only
- ✅ WordPress + PHP-FPM (without NGINX)
- ✅ MariaDB (without NGINX)
- ✅ Docker volumes for persistence
- ✅ Docker network for service communication
- ✅ Environment variables for configuration
- ✅ Automatic container restart on crash

## License

This project is part of the 42 school curriculum and is intended for educational purposes.
