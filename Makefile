CLR_G			:= \033[0;32m
CLR_Y			:= \033[0;33m
CLR_RESET		:= \033[0m

USER_NAME		:= $(shell id -un)
ifeq ($(USER_NAME),root)
USER_NAME		:= placeholder_user_name
endif

DATA_DIR		:= /home/$(USER_NAME)/data
SRC_DIR			:= srcs/
RM				:= rm -rf

SECRET_DIR		:= secrets/
SECRETS 		:= \
				$(SECRET_DIR)db_password.txt \
				$(SECRET_DIR)db_root_password.txt \
				$(SECRET_DIR)wp_password.txt \
				$(SECRET_DIR)wp_author_password.txt \
				$(SECRET_DIR)redis_password_bonus.txt

COMPOSE_FILE	:= srcs/docker-compose.yml
COMPOSE			:= docker compose -f $(COMPOSE_FILE) --project-directory srcs

WP_VOLUME		:= $(DATA_DIR)/wordpress
DB_VOLUME		:= $(DATA_DIR)/mariadb
DOMAIN_NAME		:= $(USER_NAME).42.fr

export WP_VOLUME
export DB_VOLUME
export DOMAIN_NAME

NAME			:= inception

all: $(NAME)

$(NAME): $(SRC_DIR)
	@if [ ! -f srcs/.env ]; then \
		$(MAKE) init-secrets; \
		echo "$(CLR_Y)Secrets copy created. Fill secrets before running the project!$(CLR_RESET)"; \
	fi
	@if [ ! -d $(WP_VOLUME) ]; then \
		echo "$(CLR_Y)Creating WP directory...$(CLR_RESET)"; \
		mkdir -p $(WP_VOLUME); \
	fi
	@if [ ! -d $(DB_VOLUME) ]; then \
		echo "$(CLR_Y)Creating DB directory...$(CLR_RESET)"; \
		mkdir -p $(DB_VOLUME); \
	fi
	@echo "$(CLR_G)Project is ready to run!$(CLR_RESET)"

init-secrets:
	@echo "$(CLR_Y)Initializing secrets if they don't exist...$(CLR_RESET)"
	@mkdir -p secrets
	@[ -f srcs/.env ] || cp srcs/.env.example srcs/.env
	@chmod 600 srcs/.env
	@[ -f secrets/db_password.txt ] || cp secrets/db_password.txt.example secrets/db_password.txt
	@[ -f secrets/db_root_password.txt ] || cp secrets/db_root_password.txt.example secrets/db_root_password.txt
	@[ -f secrets/wp_password.txt ] || cp secrets/wp_password.txt.example secrets/wp_password.txt
	@[ -f secrets/wp_author_password.txt ] || cp secrets/wp_author_password.txt.example secrets/wp_author_password.txt
	@[ -f secrets/redis_password_bonus.txt ] || cp secrets/redis_password_bonus.txt.example secrets/redis_password_bonus.txt
	@echo "$(CLR_G)Secrets initialized$(CLR_RESET)"

build: $(NAME)
	@echo "$(CLR_Y)Building the images...$(CLR_RESET)"
	@$(COMPOSE) build
	@echo "$(CLR_G)Build finished$(CLR_RESET)"

up: $(NAME)
	@echo "$(CLR_Y)Starting the project...$(CLR_RESET)"
	@$(COMPOSE) up -d --build
	@echo "$(CLR_G)Up: https://$(DOMAIN_NAME)$(CLR_RESET)"

rebuild: $(NAME)
	@echo "$(CLR_Y)Rebuilding from scratch...$(CLR_RESET)"
	@$(COMPOSE) build --no-cache
	@$(COMPOSE) up -d
	@echo "$(CLR_G)Rebuilt and up: https://$(DOMAIN_NAME)$(CLR_RESET)"

down:
	@echo "$(CLR_Y)Stopping stack...$(CLR_RESET)"
	@$(COMPOSE) down
	@echo "$(CLR_G)Stopped$(CLR_RESET)"

logs:
	@$(COMPOSE) logs -f

ps:
	@docker ps -a

clean:
	@echo "$(CLR_Y)Stopping the Project and removing project volumes...$(CLR_RESET)"
	@$(COMPOSE) down -v --rmi local 2>/dev/null || true
	@sudo $(RM) $(WP_VOLUME) $(DB_VOLUME)
	@echo "$(CLR_G)Project data removed$(CLR_RESET)"

# Full reset: volumes, host data, project images, build cache, secrets and .env.
# Preserves templates: secrets/*.example and srcs/.env.example.
fclean:
	@echo "$(CLR_Y)Full clean (stack, volumes, data dirs, project images, build cache, secrets, .env)...$(CLR_RESET)"
	@$(MAKE) clean
	@echo "$(CLR_Y)Pruning build cache...$(CLR_RESET)"
	@docker builder prune -af 2>/dev/null || docker buildx prune -af 2>/dev/null || true
	@echo "$(CLR_Y)Remove the secrets and the .env file? (y/n)$(CLR_RESET)"
	@read -r confirm; \
	if [ "$$confirm" = "y" ]; then \
		$(RM) $(SECRETS); \
		$(RM) srcs/.env; \
		echo "$(CLR_G)Secrets and .env removed$(CLR_RESET)"; \
	else \
		echo "$(CLR_Y)Secrets and .env not removed$(CLR_RESET)"; \
	fi
	@echo "$(CLR_G)Full clean done$(CLR_RESET)"

help:
	@echo "$(CLR_Y)Inception — Docker Compose$(CLR_RESET)"
	@echo "  make $(NAME)      Create data dirs, ensure .env / secrets are created"
	@echo "  make up           Build (if needed) and run Compose (detached)"
	@echo "  make down         Stop Compose"
	@echo "  make build        docker compose build"
	@echo "  make rebuild      build --no-cache && up -d"
	@echo "  make logs         Follow container logs"
	@echo "  make ps           docker ps -a"
	@echo "  make clean        compose down -v + remove host data dirs (images/cache kept)"
	@echo "  make fclean       full reset + --rmi local + prune build cache; keeps *example files"
	@echo "  make init-secrets Copy .env.example and secrets/*.example"

.PHONY: all help $(NAME) init-secrets build up rebuild down logs ps clean fclean