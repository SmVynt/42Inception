GREEN			= \033[0;32m
YELLOW			= \033[0;33m
RESET			= \033[0m

NAME			= inception
SRC_DIR			= srcs/
RM				= rm -rf

all: $(NAME)

$(NAME): $(SRC_DIR)
	@if [ ! -f srcs/.env ]; then \
		$(MAKE) init-secrets; \
		echo "$(YELLOW)Secrets initialized. Please fill them before running the project.$(RESET)"; \
	fi
	@echo "$(GREEN)Inception project created$(RESET)"

init-secrets:
	@echo "$(YELLOW)Initializing secrets...$(RESET)"
	@mkdir -p secrets
	@cp srcs/.env.example srcs/.env
	@chmod 600 srcs/.env
	@cp secrets/db_password.txt.example secrets/db_password.txt
	@cp secrets/db_root_password.txt.example secrets/db_root_password.txt
	@cp secrets/credentials.txt.example secrets/credentials.txt
	@echo "$(GREEN)Secrets initialized$(RESET)"

clean:
	@echo "$(YELLOW)Cleaning up...$(RESET)"
	@$(RM) $(NAME)

fclean: clean
	@echo "$(YELLOW)Removing $(NAME)...$(RESET)"
	@$(RM) $(NAME)