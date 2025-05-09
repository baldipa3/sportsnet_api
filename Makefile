# Author: Pablo Baldini
# Date Created: 07 May 2025
# Last Modified: 07 May 2025
# Description:
# Set of commands to manage API mode of the app

ARGS=$(filter-out $@,$(MAKECMDGOALS))

mix:
	docker exec backend mix $(ARGS)
