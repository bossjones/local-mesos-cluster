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
	docker-compose up -d

dev-down: check-docker-env-vars
	docker-compose stop
	docker-compose rm -f

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

open-mesos: open-marathon open-mesos

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
