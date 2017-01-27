package test

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	kube "github.com/30x/dispatcher/kubernetes"
)

func getHostsFromNamespace(nsName string) ([]string, error) {
	type HostOptions struct{}
	var hosts = map[string]HostOptions{}
	var list = []string{}

	kubeClient, err := kube.GetClient()
	if err != nil {
		return list, err
	}

	ns, err := kubeClient.Core().Namespaces().Get(nsName)
	if err != nil {
		return list, err
	}
	annotation, ok := ns.Annotations["edge/hosts"]
	if !ok {
		return list, fmt.Errorf("no hosts annotation")
	}

	err = json.Unmarshal([]byte(annotation), &hosts)
	if err != nil {
		return list, err
	}

	for host := range hosts {
		list = append(list, host)
	}

	return list, nil
}

func getRoutingSecret(nsName string) (string, error) {
	kubeClient, err := kube.GetClient()
	if err != nil {
		return "", err
	}

	secret, err := kubeClient.Core().Secrets(nsName).Get("routing")
	if err != nil {
		return "", err
	}

	data, ok := secret.Data["api-key"]
	if !ok {
		return "", fmt.Errorf("no api-key in secret")
	}

	return base64.StdEncoding.EncodeToString(data), nil

}
