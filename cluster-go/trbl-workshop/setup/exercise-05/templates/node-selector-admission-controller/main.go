package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strings"

	admissionv1 "k8s.io/api/admission/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/serializer"
)

var (
	scheme       = runtime.NewScheme()
	codecs       = serializer.NewCodecFactory(scheme)
	deserializer = codecs.UniversalDeserializer()
)

func handlePodAdmission(w http.ResponseWriter, r *http.Request) {
	var admissionReview admissionv1.AdmissionReview
	if err := json.NewDecoder(r.Body).Decode(&admissionReview); err != nil {
		http.Error(w, fmt.Sprintf("could not decode admission review: %v", err), http.StatusBadRequest)
		return
	}

	responseAdmissionReview := admissionv1.AdmissionReview{}
	responseAdmissionReview.APIVersion = admissionReview.APIVersion
	responseAdmissionReview.Kind = admissionReview.Kind

	admissionResponse := admissionv1.AdmissionResponse{
		UID: admissionReview.Request.UID,
	}

	var pod corev1.Pod
	if err := json.Unmarshal(admissionReview.Request.Object.Raw, &pod); err != nil {
		admissionResponse.Allowed = false
		admissionResponse.Result = &metav1.Status{
			Message: err.Error(),
		}
	} else {
		namespace := admissionReview.Request.Namespace
		if strings.HasPrefix(namespace, "exercise05") {
			if pod.Spec.NodeSelector == nil || len(pod.Spec.NodeSelector) == 0 {
				admissionResponse.Allowed = false
				admissionResponse.Result = &metav1.Status{
					Message: "Pods in namespaces starting with 'exercise05' must specify a NodeSelector",
				}
			} else {
				admissionResponse.Allowed = true
			}
		} else {
			admissionResponse.Allowed = true
		}
	}

	responseAdmissionReview.Response = &admissionResponse

	if err := json.NewEncoder(w).Encode(responseAdmissionReview); err != nil {
		http.Error(w, fmt.Sprintf("could not encode response admission review: %v", err), http.StatusInternalServerError)
		return
	}
}

func main() {
	http.HandleFunc("/admit", handlePodAdmission)

	certFile := os.Getenv("TLS_CERT_FILE")
	keyFile := os.Getenv("TLS_KEY_FILE")

	port := os.Getenv("PORT")
	if port == "" {
		port = "8443"
	}

	if certFile == "" || keyFile == "" {
		fmt.Println("Please provide TLS_CERT_FILE and TLS_KEY_FILE environment variables")
		os.Exit(1)
	}

	fmt.Printf("Starting server on port %s...\n", port)
	if err := http.ListenAndServeTLS(":"+port, certFile, keyFile, nil); err != nil {
		panic(err)
	}
}

