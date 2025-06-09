# Author: Pablo Baldini
# Date Created: 07 May 2025
# Last Modified: 07 May 2025
# Description:
# Set of commands to manage API mode of the app

ARGS=$(filter-out $@,$(MAKECMDGOALS))

.PHONY: test

mix:
	docker exec backend mix $(ARGS)

db-shell:
	docker exec -it sportsnet-postgres-1 psql -U postgres -d postgres

db-migrate:
	docker exec backend mix ecto.migrate

db-seed:
	docker exec backend mix run priv/repo/seeds.exs

db-create:
	docker exec backend mix ecto.create

repl:
	docker exec -it backend iex -S mix

sh:
	docker exec -it backend sh

test:
	docker exec backend mix test $(ARGS)

attach:
	docker attach --sig-proxy=false --detach-keys="ctrl-c" backend

up:
	docker start backend

up:
	@echo "Starting backend container..." && \
	docker start backend

restart:
	@echo "Restarting backend container..." && \
	docker restart backend

down:
	@echo "Stopping backend container..." && \
	docker stop backend

test:
	docker exec -it backend iex -S mix test --trace $(ARGS)
