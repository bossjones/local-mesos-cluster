export DOCKER_IP = $(shell which docker-machine > /dev/null 2>&1 && docker-machine ip $(DOCKER_MACHINE_NAME))

# verify that certain variables have been defined off the bat
check_defined = \
	$(foreach 1,$1,$(__check_defined))
__check_defined = \
	$(if $(value $1),, \
	  $(error Undefined $1$(if $(value 2), ($(strip $2)))))

list_allowed_args := product ip command

RED=\033[0;31m
GREEN=\033[0;32m
ORNG=\033[38;5;214m
BLUE=\033[38;5;81m
NC=\033[0m

export RED
export GREEN
export NC
export ORNG
export BLUE

# .DEFAULT_GOAL:=list

DOCKER_COMPOSE:=docker-compose -f docker-compose.yml
DOCKER_COMPOSE_NOTEBOOK:=docker-compose -f docker-compose.yml -f docker-compose-spark.yml
DOCKER:=docker

check-docker-env-vars:
	@echo "DOCKER_HOST = \"$$DOCKER_HOST\""; \
	echo "DOCKER_IP = \"$$DOCKER_IP\""; \
	if [ -z "$$DOCKER_HOST" ]; then \
		echo "DOCKER_HOST is not set. Check your docker-machine is running or do \"eval \$$(docker-machine env local-mesos-cluster)\"?" 1>&2; \
		exit 1; \
	fi; \
	if [ -z "$$DOCKER_IP" ]; then \
		echo "DOCKER_IP is not set. Check your docker-machine is running or do \"eval \$$(docker-machine env local-mesos-cluster)\"?" 1>&2; \
		exit 1; \
	fi; \
	if [ "$$DOCKER_IP" = "127.0.0.1" ]; then \
		echo "DOCKER_IP is set to a loopback address. Check your docker-machine is running or do \"eval \$$(docker-machine env)\"?" 1>&2; \
		exit 1; \
	fi

dev-up: check-docker-env-vars
	$(DOCKER_COMPOSE) up -d

dev-down: check-docker-env-vars
	$(DOCKER_COMPOSE) stop
	$(DOCKER_COMPOSE) rm -f

dev-up-with-jupyter: check-docker-env-vars
	$(DOCKER_COMPOSE_NOTEBOOK) up -d
	$(DOCKER) inspect localmesoscluster_pyspark_1 | jq
	$(DOCKER) inspect localmesoscluster_slave-one_1 | jq
	$(DOCKER) inspect localmesoscluster_slave-two_1 | jq
	$(DOCKER) inspect localmesoscluster_slave-three_1 | jq

dev-down-with-jupyter: check-docker-env-vars
	$(DOCKER_COMPOSE_NOTEBOOK) stop
	$(DOCKER_COMPOSE_NOTEBOOK) rm -f

db-conn:
	mkdir -p var/mysql-container-home
	docker run \
		-it \
		--rm \
		--net=localmesoscluster_default \
		--link localmesoscluster_mysql-db_1:mysql \
		-v $$(pwd)/var/mysql-container-home:/root \
		mysql \
		sh -c \
			'exec mysql \
				--host=mysql --port=3306 \
				--user=root --password=password \
				db'

docker-clean:
	@docker rm -v $$(docker ps --no-trunc -a -q); docker rmi $$(docker images -q --filter "dangling=true")

phpmyadmin:
	docker-compose up -d phpmyadmin
	sleep 1
	python -m webbrowser -t http://$(DOCKER_IP):'3380/sql.php?server=1&db=db&table=ImageDefinition'

zk-shell:
	docker run -e LC_ALL=C.UTF-8 -it --rm creack/zk-shell zk-shell $(DOCKER_IP):2181

open-marathon:
	open http://$$(docker-machine ip local-mesos-cluster):8080

open-mesos:
	open http://$$(docker-machine ip local-mesos-cluster):5050

open: open-marathon open-mesos

open-mesos-marathon: open-marathon open-mesos

open-jupyter:
	open http://$$(docker-machine ip local-mesos-cluster):8888

open-all: open-mesos-marathon open-jupyter

bootstrap-docker-machine:
	docker-machine create -d virtualbox \
	--virtualbox-memory 6000 \
	--virtualbox-cpu-count 2 \
	local-mesos-cluster

install-virtualenv-osx:
	ARCHFLAGS="-arch x86_64" LDFLAGS="-L/usr/local/opt/openssl/lib" CFLAGS="-I/usr/local/opt/openssl/include" pip install -r requirements.txt

upgrade-pip-base-packages:
	pip install --ignore-installed --pre "https://github.com/pradyunsg/pip/archive/hotfix/9.0.2.zip#egg=pip"
	pip install --upgrade setuptools==36.0.1 wheel==0.29.0

list:
	@$(MAKE) -qp | awk -F':' '/^[a-zA-Z0-9][^$#\/\t=]*:([^=]|$$)/ {split($$1,A,/ /);for(i in A)print A[i]}' | sort

registry-start:
	docker run -d -p 5000:5000 --restart=always --name registry \
	--rm \
	-v `pwd`/certs:/certs \
	-v `pwd`/data:/var/lib/registry \
	-e "REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt" \
	-e "REGISTRY_HTTP_TLS_KEY=/certs/domain.key" \
	registry:2

registry-stop:
	docker kill registry
	echo "--------"
	docker ps
	echo "--------"
	@$(MAKE) docker-clean

scp-ssl-registry-script-to-docker-machine:
	docker-machine scp ./scripts/generate-ssl-registry-run-on-docker-machine.sh local-mesos-cluster:.
	@echo "Now pull down the certs into ./certs"
	# FIXME: Maybe have this call make itself, so no code duplication required
	docker-machine scp local-mesos-cluster:certs/domain.crt ./certs/domain.crt
	docker-machine scp local-mesos-cluster:certs/domain.key ./certs/domain.key

scp-certs-to-host:
	docker-machine scp local-mesos-cluster:certs/domain.crt ./certs/domain.crt
	docker-machine scp local-mesos-cluster:certs/domain.key ./certs/domain.key

# eg. localmesoscluster
# This can be used to generate network name, like localmesoscluster_default
generate-docker-network-name:
	python -c "import re;name='$(basename $(pwd))';print re.sub(r'[^a-z0-9]', '', name.lower())"

dcos-config-set:
	dcos config set core.mesos_master_url http://$$(docker-machine ip local-mesos-cluster):5050
	dcos config set marathon.url http://$$(docker-machine ip local-mesos-cluster):8080

mesosctl:
	docker run --net=host -it mesoshq/mesosctl mesosctl

multitail-usage:
	@echo '[run] multitail has an in-built interactive help that you should be able to learn a lot from. h is your friend. I won’t mention all the shorcuts here, but here’s a list of quick one that I use fairly often.'
	@echo '[run] h for interactive help'
	@echo '[run] q to get back one step / quit'
	@echo '[run] U to get back to default view'
	@echo '[run] u to exclusively view a log'
	@echo '[run] z to hide a log'
	@echo '[run] b to scrollback a log'
	@echo '[run] B to scrollback the interspered log'

# source: http://suva.sh/posts/using-multitail-with-docker-compose-to-group-interspersed-logs
multitail-agents:
	multitail -o beep_method:popup                           \
	          -cT ansi -l '$(DOCKER_COMPOSE) logs -f slave-one'     \
	          -cT ansi -l '$(DOCKER_COMPOSE) logs -f slave-two'  \
	          -cT ansi -l '$(DOCKER_COMPOSE) logs -f slave-three'

multitail-zk-etcd:
	multitail -o beep_method:popup                           \
	          -cT ansi -l '$(DOCKER_COMPOSE) logs -f zk'     \
	          -cT ansi -l '$(DOCKER_COMPOSE) logs -f etcd'

logs:
	$(if $(SERVICE_NAME), $(info -- Tailing logs for $(SERVICE_NAME)), $(info -- Tailing all logs, SERVICE_NAME not set.))
	$(DOCKER_COMPOSE) logs -f $(SERVICE_NAME)
