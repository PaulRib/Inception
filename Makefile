all:
	@mkdir -p /home/pribolzi/data/db
	@mkdir -p /home/pribolzi/data/wp
	@docker compose -f ./srcs/docker-compose.yml up --build

fclean:
	@docker compose -f ./srcs/docker-compose.yml down --rmi all -v
	@sudo rm -rf /home/pribolzi/data/db
	@sudo rm -rf /home/pribolzi/data/wp
	@docker system prune -f

re: fclean all

.PHONY : all fclean re