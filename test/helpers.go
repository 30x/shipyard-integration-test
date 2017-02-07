package test

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	kube "github.com/30x/dispatcher/kubernetes"
	. "github.com/onsi/gomega"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
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

func newFileUploadRequest(hostBase string, organization string, application string, path string) *http.Response {
	file, err := os.Open(path)
	Expect(err).Should(BeNil())
	defer file.Close()

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	part, err := writer.CreateFormFile("file", filepath.Base(path))
	Expect(err).Should(BeNil())
	_, err = io.Copy(part, file)
	Expect(err).Should(BeNil())

	writer.WriteField("name", application)

	//set the content type
	writer.FormDataContentType()

	err = writer.Close()
	Expect(err).Should(BeNil())

	uri := fmt.Sprintf("%sorganizations/%s/apps", hostBase, organization)
	request, err := http.NewRequest("POST", uri, body)
	Expect(err).Should(BeNil())

	request.Host = ShipyardHost
	request.Header.Add("Host", ShipyardHost)
	request.Header.Set("Content-Type", writer.FormDataContentType())
	request.Header.Set("Authorization", "Bearer "+os.Getenv("TOKEN"))

	client := &http.Client{}

	response, err := client.Do(request)
	Expect(err).Should(BeNil())
	return response
}
