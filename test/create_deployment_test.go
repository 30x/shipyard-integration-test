package test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"bytes"
	"fmt"
	"net/http"
	"os"
	"time"
)

var _ = Describe("Create Deployment", func() {

	// Create the deployment then run validaiton test on it
	postBody := `{
              "deploymentName": "dep1",
              "edgePaths": [{
                "basePath": "/base",
                "containerPort": "3000",
                "targetPath": "/target"
              }],
              "replicas": 1,
              "envVars": [
              {
                "name": "test1",
                "value": "value1"
              }]
            }`

	client := http.Client{}

	createUrl := fmt.Sprintf("%senvironments/%s:%s/deployments", os.Getenv("API_BASE_PATH"), os.Getenv("APIGEE_ORG"), os.Getenv("APIGEE_ENV"))
	req, err := http.NewRequest("POST", createUrl, bytes.NewBufferString(postBody))
	Expect(err).Should(BeNil(), "Create deployment api init call err should not be nil")
	req.Host = ShipyardHost
	req.Header.Add("Host", ShipyardHost)
	req.Header.Add("Content-Type", "application/json")
	req.Header.Add("Authorization", "Bearer "+os.Getenv("TOKEN"))
	resp, err := client.Do(req)
	Expect(err).Should(BeNil(), "Create deployment api call err should not be nil")
	resp.Body.Close()

	// Wait..
	time.Sleep(10 * time.Second)

	It("Validate HTTP Response", func() {
		Expect(resp.StatusCode).To(Equal(201))
		// Has Location Header
		Expect(resp.Header.Get("Location")).ShouldNot(Equal(""))
	})

	It("Validate Deployment Resource Exists in Enrober", func() {
		resourceUrl := fmt.Sprintf("%senvironments/%s:%s/deployments/dep1", os.Getenv("API_BASE_PATH"), os.Getenv("APIGEE_ORG"), os.Getenv("APIGEE_ENV"))

		getReq, err := http.NewRequest("GET", resourceUrl, nil)
		getReq.Host = ShipyardHost
		getReq.Header.Add("Host", ShipyardHost)
		getReq.Header.Add("Authorization", "Bearer "+os.Getenv("TOKEN"))
		getResp, err := client.Do(getReq)
		Expect(err).Should(BeNil())
		Expect(getResp.StatusCode).To(Equal(200))
	})

	It("Validate Dispatcher Routes Traffic to Deployment", func() {

		hosts, err := getHostsFromNamespace(os.Getenv("APIGEE_ORG") + "-" + os.Getenv("APIGEE_ENV"))
		Expect(err).Should(BeNil())

		routingSecret, err := getRoutingSecret(os.Getenv("APIGEE_ORG") + "-" + os.Getenv("APIGEE_ENV"))
		Expect(err).Should(BeNil())

		for _, host := range hosts {
			resourceUrl := fmt.Sprintf("%sbase", os.Getenv("API_BASE_PATH"))

			// Make sure we are getting a 403 without the routing key
			getReq, err := http.NewRequest("GET", resourceUrl, nil)
			Expect(err).Should(BeNil())
			getReq.Host = host
			getReq.Header.Add("Host", host)
			getResp, err := client.Do(getReq)
			Expect(err).Should(BeNil())
			Expect(getResp.StatusCode).To(Equal(403))

			// Make sure we are getting a 200 with the routing key
			getReq, err = http.NewRequest("GET", resourceUrl, nil)
			Expect(err).Should(BeNil())
			getReq.Host = host
			getReq.Header.Add("Host", host)
			getReq.Header.Add("X-ROUTING-API-KEY", routingSecret)
			getResp, err = client.Do(getReq)
			Expect(err).Should(BeNil())
			Expect(getResp.StatusCode).To(Equal(200))
		}
	})

})
