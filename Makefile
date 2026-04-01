GREEN			= \033[0;32m
YELLOW			= \033[0;33m
RESET			= \033[0m

USER_NAME		:= $(shell id -un)
ifeq ($(USER_NAME),root)
USER_NAME		:= placeholder_user_name
endif

DATA_DIR		:= /home/$(USER_NAME)/data
NAME			:= inception
SRC_DIR			:= srcs/
RM				:= rm -rf

COMPOSE_FILE	:= srcs/docker-compose.yml
COMPOSE			:= docker compose -f $(COMPOSE_FILE) --project-directory srcs

WP_VOLUME		:= $(DATA_DIR)/wordpress
DB_VOLUME		:= $(DATA_DIR)/mariadb
DOMAIN_NAME		:= $(USER_NAME).42.fr

all: $(NAME)

$(NAME): $(SRC_DIR)
	@if [ ! -f srcs/.env ]; then \
		$(MAKE) init-secrets; \
		echo "$(YELLOW)Secrets initialized. Please fill them before running the project.$(RESET)"; \
	fi
	@echo "$(YELLOW)Creating data directories...$(RESET)"
	@mkdir -p $(WP_VOLUME)
	@mkdir -p $(DB_VOLUME)
	@echo "$(GREEN)Data directories created$(RESET)"
	@echo "$(GREEN)Inception project created$(RESET)"

init-secrets:
	@echo "$(YELLOW)Initializing secrets...$(RESET)"
	@mkdir -p secrets
	@cp srcs/.env.example srcs/.env
	@chmod 600 srcs/.env
	@cp secrets/db_password.txt.example secrets/db_password.txt
	@cp secrets/db_root_password.txt.example secrets/db_root_password.txt
	@cp secrets/wp_password.txt.example secrets/wp_password.txt
	@echo "$(GREEN)Secrets initialized$(RESET)"

up:
	@echo "$(YELLOW)Starting the project...$(RESET)"
	@export WP_VOLUME="$(WP_VOLUME)" && \
		export DB_VOLUME="$(DB_VOLUME)" && \
		export DOMAIN_NAME="$(DOMAIN_NAME)" && \
		export USER_NAME="$(USER_NAME)" && \
		$(COMPOSE) up -d --build
	@echo "$(GREEN)Project started$(RESET)"

down:
	@echo "$(YELLOW)Stopping the project...$(RESET)"
	$(COMPOSE) down
	@echo "$(GREEN)Project stopped$(RESET)"

show-status:
	@docker ps -a

clean:
	@echo "$(YELLOW)Cleaning up...$(RESET)"
	@$(RM) $(DATA_DIR)/wordpress
	@$(RM) $(DATA_DIR)/mariadb
	@echo "$(GREEN)Data directories removed$(RESET)"

fclean: clean
	@echo "$(YELLOW)This will remove all the secrets and the environment file.$(RESET)"
	@read -p "Are you sure you want to continue? (y/n) " confirm; \
	if [ "$$confirm" = "y" ]; then \
		$(RM) secrets/db_password.txt; \
		$(RM) secrets/db_root_password.txt; \
		$(RM) secrets/wp_password.txt; \
		echo "$(GREEN)Secrets removed$(RESET)"; \
		$(RM) srcs/.env; \
		echo "$(GREEN)Environment file removed$(RESET)"; \
	else \
		echo "$(YELLOW)Aborting...$(RESET)"; \
	fi
