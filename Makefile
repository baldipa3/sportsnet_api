# Author: Pablo Baldini
# Date Created: 07 May 2025
# Last Modified: 09 Jun 2025
# Description:
# Set of commands to manage API mode of the app

ARGS=$(filter-out $@,$(MAKECMDGOALS))
FRONTEND_DIR = ../sportsnet

.PHONY: test

mix:
	docker exec backend mix $(ARGS)

db-shell:
	docker exec -it sportsnet-postgres-1 psql -U postgres -d postgres

db-migrate:
	docker exec backend mix ecto.migrate

db-seed:
	docker exec backend mix run priv/repo/seeds.exs

db-migration:
	docker exec backend mix ecto.gen.migration $(ARGS)

db-reset:
	mix ecto.reset

repl:
	docker exec -it backend iex -S mix

sh:
	docker exec -it backend sh

attach:
	docker attach --sig-proxy=false --detach-keys="ctrl-c" backend

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

gen-schema:
	echo "Generating GraphQL schema..." && \
	docker exec backend mix absinthe.schema.sdl --schema SportsnetApiWeb.Schema 2>/dev/null && \
	docker cp backend:/app/schema.graphql ${FRONTEND_DIR}/src/schema.graphql && \
	docker exec backend rm /app/schema.graphql && \
	echo "Schema copied to frontend src/schema.graphql"

gen-token:
	@echo "Requesting API token..." && \
	curl -s -X POST http://localhost:4000/users/login \
		-H "Content-Type: application/json" \
		-d '{ "user": { "email": "john.doe@gmail.com", "password": "Password123" } }' \
	| jq -r '.data.token'
