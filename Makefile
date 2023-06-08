DOCKER_COMPOSE_BIN ?= docker compose
DOCKER_COMPOSE = DOCKER_UID=$(shell id -u) $(DOCKER_COMPOSE_BIN) -f docker-compose.yaml

EXEC?=$(DOCKER_COMPOSE) exec php

help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

build:
	$(DOCKER_COMPOSE) -f docker-compose.yaml build

push:
	$(DOCKER_COMPOSE) -f docker-compose.yaml push

phpstan:
	$(DOCKER_COMPOSE) run --rm --no-deps php vendor/bin/phpstan analyse -l 8 src

cs-fixer:
	$(DOCKER_COMPOSE) run --rm --no-deps php vendor/bin/php-cs-fixer fix

cs:
	$(DOCKER_COMPOSE) run --rm --no-deps php vendor/bin/php-cs-fixer --dry-run --diff fix

permissions:
	$(DOCKER_COMPOSE) run --rm --no-deps php chown -R www-data var/

install: build start                                                                                   ## Create and start docker containers

start:                                                                                                 ## Start docker containers
	$(DOCKER_COMPOSE) up -d

stop:                                                                                                  ## Stop docker containers
	$(DOCKER_COMPOSE) stop

restart:                                                                                               ## Restart docker containers
	$(DOCKER_COMPOSE) restart

shell:
	$(DOCKER_COMPOSE) exec php bash

database-fixture-load:
	$(DOCKER_COMPOSE) run --rm --no-deps php bin/console doctrine:fixture:load -n

database-reset:
	$(DOCKER_COMPOSE) exec php php bin/console doctrine:database:drop --force
	$(DOCKER_COMPOSE) exec php php bin/console doctrine:database:create
	$(DOCKER_COMPOSE) exec php php bin/console doctrine:migration:migrate --no-interaction

test-functional:
	$(DOCKER_COMPOSE) exec php bin/console --env=test doctrine:database:create --if-not-exists
	$(DOCKER_COMPOSE) exec php bin/console --env=test doctrine:migration:migrate --no-interaction
	$(DOCKER_COMPOSE) exec php bin/phpunit tests/Functional/

test-unit:
	$(DOCKER_COMPOSE) exec php bin/phpunit tests/Unit/
