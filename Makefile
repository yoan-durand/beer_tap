.PHONY: docker-build start stop down install setup php destroy down migrate diff require help bash require reset_bdd fixtures

.DEFAULT_GOAL: help

CONTAINER="php"

COMMAND="c:c"

COMPOSE_DEV_FILE= 'docker-compose-dev.yml'

OS_INFORMATION:=$(shell uname -s)

RUN_ACL:= sudo setfacl -dR -m u:$(shell whoami):rwX -m u:1000:rwX -m u:33:rwX ./ && \
          sudo setfacl -R -m u:$(shell whoami):rwX -m u:1000:rwX -m u:33:rwX ./

ifeq (${OS_INFORMATION}, Darwin)
COMPOSE_DEV_FILE="docker-compose-dev-mac.yml"
RUN_ACL:= sudo dseditgroup -o edit -a $(shell id -un) -t user $(shell id -gn 1000)
else
ifneq (${OS_INFORMATION}, Linux)
COMPOSE_DEV_FILE="docker-compose-dev-win.yml"
endif
endif

PROJECT_PATH_BACK = $(shell echo ${PWD})

help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-10s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

build: ## Lance le build des conteneur docker
	docker-compose -f docker-compose.yml -f ${COMPOSE_DEV_FILE} build

start: ## Demmare les conteneurs docker
	docker-compose -f docker-compose.yml -f ${COMPOSE_DEV_FILE} up -d

stop: ## Arrete les conteneurs docker
	docker-compose -f docker-compose.yml -f ${COMPOSE_DEV_FILE} stop

destroy: ## Arretes les conteneurs en detruisant les conteneurs, volumes et network associee.
	docker-compose -f docker-compose.yml -f ${COMPOSE_DEV_FILE} down --volumes

install: acl .env #vendor ## Lance le script d'install
	docker-compose -f docker-compose.yml -f ${COMPOSE_DEV_FILE} exec -u 33:33 php ./automation/bin/install.sh --mode dev

reset_schema: ## recréer la base de données
	docker-compose -f docker-compose.yml -f ${COMPOSE_DEV_FILE} exec -u 33:33 php ./bin/console do:d:drop --force
	docker-compose -f docker-compose.yml -f ${COMPOSE_DEV_FILE} exec -u 33:33 php ./bin/console do:d:c

migrate: ## Execute les migrations
	docker-compose -f docker-compose.yml -f ${COMPOSE_DEV_FILE} exec -u 33:33 php ./bin/console do:mi:mi

diff: ## Genere les fichiers de migrations Doctrine
	docker-compose -f docker-compose.yml -f ${COMPOSE_DEV_FILE} exec -u 33:33 php ./bin/console do:mi:di

fixtures: ## insert les fixtures dans la bdd
	docker-compose -f docker-compose.yml -f ${COMPOSE_DEV_FILE} exec -u 33:33 php ./bin/console h:f:l

sfconsole: ## Execute une commande symfony. ex: make sfconsole COMMAND="d:d:d"
	docker-compose -f docker-compose.yml -f ${COMPOSE_DEV_FILE} exec -u 33:33 $(CONTAINER) ./bin/console $(COMMAND)

composer.lock: composer.json ## Composer update
	docker run --rm \
    --volume $(PROJECT_PATH_BACK):/var/www/html \
    --workdir /var/www/html\
    -u 33:33 \
    anasdox/phpwebbuilder \
    composer update --no-interaction --ignore-platform-reqs

vendor: composer.json ## Composer install
	docker run --rm \
    --volume $(PROJECT_PATH_BACK):/var/www/html \
    --workdir /var/www/html \
    -u 33:33 \
    anasdox/phpwebbuilder \
    composer install --no-interaction --classmap-authoritative --ignore-platform-reqs

require: ## Composer require
	docker run --rm \
        --volume $(PROJECT_PATH_BACK):/var/www/html \
        --workdir /var/www/html \
        -u 33:33 \
        anasdox/phpwebbuilder \
        composer require ${PACKAGE} --no-interaction --ignore-platform-reqs

dump-autoload: ## Composer dump-autoload
	docker run --rm \
        --volume $(PROJECT_PATH_BACK):/var/www/html \
        --workdir /var/www/html \
        -u 33:33 \
        anasdox/phpwebbuilder \
        composer dump-autoload

bash: ## Connexion a un conteneur par defaut php. Renseigner CONTAINER="nom du conteneur" pour ce connecter a un conteneur
	docker-compose -f docker-compose.yml -f ${COMPOSE_DEV_FILE} exec -u 33:33 $(CONTAINER) bash

setup: acl .env build start vendor ## Tache d'initialisation de l'environnement

#reset_bdd: reset_schema migrate fixtures ## Tache de reset de la base de données
#
#swagger: ## Genere le fichier swagger.json
#	docker-compose -f docker-compose.yml -f ${COMPOSE_DEV_FILE} exec php ./bin/console api:swagger:export >> swagger.json
#
#node_modules: package.json ## yarn install
#	docker run --rm \
#        --volume $(PROJECT_PATH_BACK):/var/www/html \
#        --workdir /var/www/html \
#        -u 33:33 \
#        anasdox/phpwebbuilder \
#        yarn install
#
#yarn: package.json ## Execute une commande yarn. ex: make yarn COMMAND="run encore dev"
#	docker run --rm \
#        --volume $(PROJECT_PATH_BACK):/var/www/html \
#        --workdir /var/www/html \
#        -u 33:33 \
#        anasdox/phpwebbuilder \
#        yarn $(COMMAND_YARN)
#
#yarn.lock: package.json
#	docker run --rm \
#        --volume $(PROJECT_PATH_BACK):/var/www/html \
#        --workdir /var/www/html \
#        -u 33:33 \
#        anasdox/phpwebbuilder \
#        yarn upgrade

.env: .env.dist
	cp .env.dist .env

acl: ## Donne les droits d'ecriture sur le dossier
	$(RUN_ACL)