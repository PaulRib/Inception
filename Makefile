# Variables
NAME          = inception
COMPOSE_FILE  = ./srcs/docker-compose.yml
DATA_PATH     = /home/pribolzi/data

# Couleurs pour le terminal
GREEN         = \033[0;32m
RED           = \033[0;31m
YELLOW        = \033[0;33m
RESET         = \033[0m

# --- Règles Principales ---

all: setup build

setup:
	@echo "$(YELLOW)Configuration des répertoires de données...$(RESET)"
	@sudo mkdir -p $(DATA_PATH)/db
	@sudo mkdir -p $(DATA_PATH)/wp
	@echo "$(GREEN)Dossiers créés.$(RESET)"

build:
	@echo "$(YELLOW)Lancement de la compilation des containers...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) up --build -d
	@echo "$(GREEN)Inception est opérationnel !$(RESET)"

stop:
	@echo "$(YELLOW)Arrêt des containers...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) stop
	@echo "$(GREEN)Containers arrêtés.$(RESET)"

down:
	@echo "$(YELLOW)Suppression des containers...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) down
	@echo "$(GREEN)Containers supprimés.$(RESET)"

# --- Nettoyage ---

clean: down
	@echo "$(YELLOW)Nettoyage des containers inutilisés...$(RESET)"
	@docker system prune -a -f
	@echo "$(GREEN)Nettoyage effectué.$(RESET)"

fclean:
	@echo "$(RED)Suppression totale : containers, images, volumes et données...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) down -v --rmi all
	@sudo rm -rf $(DATA_PATH)
	@docker system prune -a --volumes -f
	@echo "$(GREEN)Tout a été supprimé.$(RESET)"

re: fclean all

# --- Utilitaires ---

status:
	@docker ps
	@echo ""
	@docker volume ls
	@echo ""
	@docker network ls

.PHONY: all setup build stop down clean fclean re status