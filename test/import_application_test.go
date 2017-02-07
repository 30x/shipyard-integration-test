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

var _ = Describe("Import Application", func() {

	It("Import and Test if Version Exists in Kiln", func() {
		res := newFileUploadRequest(os.Getenv("API_BASE_PATH"), os.Getenv("APIGEE_ORG"), "test-app", "../fixture/working-app.zip")
		Expect(res.StatusCode).To(Equal(201))
		//revUrl := res.Header["Location"]
		location := res.Header["Location"][0]
		rev := location[strings.LastIndex(location, "/")+1:]

		revUrl := fmt.Sprintf("%sorganizations/%s/apps/test-app/version/%s", os.Getenv("API_BASE_PATH"), os.Getenv("APIGEE_ORG"), rev)

		// Wait..
		time.Sleep(10 * time.Second)

		client := http.Client{}
		getReq, err := http.NewRequest("GET", revUrl, nil)
		Expect(err).Should(BeNil())
		getReq.Host = ShipyardHost
		getReq.Header.Add("Host", ShipyardHost)
		getReq.Header.Set("Authorization", "Bearer "+os.Getenv("TOKEN"))
		getResp, err := client.Do(getReq)
		Expect(err).Should(BeNil())
		Expect(getResp.StatusCode).To(Equal(200))
	})

	It("Import and Deploy to Enrober", func() {
		res := newFileUploadRequest(os.Getenv("API_BASE_PATH"), os.Getenv("APIGEE_ORG"), "new-test-app", "../fixture/working-app.zip")
		Expect(res.StatusCode).To(Equal(201))
		//revUrl := res.Header["Location"]
		location := res.Header["Location"][0]
		rev := location[strings.LastIndex(location, "/")+1:]

		// Wait..
		time.Sleep(10 * time.Second)

		// Deploy to Enrober

		// Create the deployment then run validaiton test on it
		postBody := `{
              "deploymentName": "new-test-app",
              "edgePaths": [{
                "basePath": "/base",
                "containerPort": "3000",
                "targetPath": "/target"
              }],
              "revision": ` + rev + `
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
	})

})
