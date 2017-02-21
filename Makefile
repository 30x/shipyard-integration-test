# Container configuration, what are we testing
export ENROBER_TAG=v0.7.1
export DISPATCHER_TAG=latest
export KILN_TAG=0.1.19

# Base path for all API calls
export AUTH_API_HOST=https://api.e2e.apigee.net/
export API_BASE_PATH=http://$(shell minikube ip 2> /dev/null):30555/

# Apigee Test Org use mine for now i guess
export APIGEE_ORG=adammagaluk1
export APIGEE_ENV=test

# Get apigee token
export TOKEN=$(shell SSO_LOGIN_URL=https://login.e2e.apigee.net get_token)

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
	kubectl create -f deploy/shipyard-all.yaml

setup: setup-containers setup-k8s

teardown: test-kubectl
	kubectl delete --ignore-not-found=true ns/shipyard

test: test-kubectl
	go test -v ./test/...
