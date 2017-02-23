# Shipyard Integration Test

## Requirements

1. Minikube - https://github.com/kubernetes/minikube#installation

2. Install `get_token` from Apigee. `curl https://login.apigee.com/resources/scripts/sso-cli/ssocli-bundle.zip -o "ssocli-bundle.zip"` and `sudo ./install -b /usr/local/bin`

## Running Local

1. Start minikube `minikube start`

1. Make sure kubectl is using minikube context. `kubectl config use-context minikube`

1. Setup docker env. `eval $(minikube docker-env)`

1. Setup shipyard k8s deployment. `make setup`. This pulls the image tags for each project and tags them as latest in minikube. Then it deploys `deploy/shipyard-all.yaml`

1. `make test` This runs the Integration test suite in `tests/...` For now only create deployment is setup.

## Tearing Down

`make teardown` to remove apigee/shipyard namespaces from k8s.

## Setting up /etc/hosts

Get minikube ip `minikube ip` and add to `/etc/hosts`.

`192.168.99.100  api.shipyard.dev`

Calls to `http://api.shipyard.dev:30555/environments` will hit enrober.
