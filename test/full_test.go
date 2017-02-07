package test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"bytes"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"
)

var _ = Describe("Kiln / Enrober / Dispatcher Integration", func() {

	It("Import and Deploy and Test Route", func() {
		res := newFileUploadRequest(os.Getenv("API_BASE_PATH"), os.Getenv("APIGEE_ORG"), "test-app-full", "../fixture/working-app.zip")
		Expect(res.StatusCode).To(Equal(201))
		location := res.Header["Location"][0]
		rev := location[strings.LastIndex(location, "/")+1:]

		// Wait..
		time.Sleep(10 * time.Second)

		// Deploy to Enrober

		// Create the deployment then run validaiton test on it
		postBody := `{
              "deploymentName": "test-app-full",
              "revision": ` + rev + `,
              "envVars": [
              {
                "name": "PORT",
                "value": "9000"
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
		Expect(resp.StatusCode).To(Equal(201))
		resp.Body.Close()

		// Wait..
		time.Sleep(10 * time.Second)

		hosts, err := getHostsFromNamespace(os.Getenv("APIGEE_ORG") + "-" + os.Getenv("APIGEE_ENV"))
		Expect(err).Should(BeNil())

		routingSecret, err := getRoutingSecret(os.Getenv("APIGEE_ORG") + "-" + os.Getenv("APIGEE_ENV"))
		Expect(err).Should(BeNil())

		for _, host := range hosts {
			resourceUrl := fmt.Sprintf("%stest-app-full", os.Getenv("API_BASE_PATH"))

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
