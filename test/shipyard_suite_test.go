package test

import (
	kube "github.com/30x/dispatcher/kubernetes"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"os"
	"testing"
)

const (
	ShipyardHost = "api.shipyard.dev"
)

func TestShipyard(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Shipyard Integration Suite")
}

var _ = BeforeSuite(func() {

})

var _ = AfterSuite(func() {
	kubeClient, err := kube.GetClient()
	Expect(err).Should(BeNil())
	kubeClient.Core().Namespaces().Delete(os.Getenv("APIGEE_ORG")+"-"+os.Getenv("APIGEE_ENV")+"asd", nil)
})
