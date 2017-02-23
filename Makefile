# Container configuration, what are we testing
export ENROBER_TAG=v0.9.1
export DISPATCHER_TAG=latest
export KILN_TAG=0.1.19

test-kubectl:
	/bin/sh -c 'if [ "$$(kubectl config current-context)" != "minikube" ]; then exit 1; fi'

.ONESHELL:
.SHELLFLAGS = -e
setup-containers: setup-registry
	$(eval $(shell minikube docker-env))
	docker pull thirtyx/kiln:$(KILN_TAG)
	docker tag thirtyx/kiln:$(KILN_TAG) thirtyx/kiln

	docker pull thirtyx/enrober:$(ENROBER_TAG)
	docker tag thirtyx/enrober:$(ENROBER_TAG) thirtyx/enrober

	docker pull thirtyx/dispatcher:$(DISPATCHER_TAG)
	docker tag thirtyx/dispatcher:$(DISPATCHER_TAG) thirtyx/dispatcher

# 	For testing without kiln
	docker pull thirtyx/nodejs-k8s-env:latest
	docker tag thirtyx/nodejs-k8s-env localhost:5000/$(APIGEE_ORG)/dep1:0
	docker push localhost:5000/$(APIGEE_ORG)/dep1:0

setup-registry: test-kubectl
	kubectl apply -f deploy/local-registry.yml

setup-k8s: test-kubectl
	kubectl apply -f deploy/shipyard-all.yaml

setup: setup-containers setup-k8s

teardown: test-kubectl
	kubectl delete --ignore-not-found=true ns/shipyard

test:
	./run_tests.sh
