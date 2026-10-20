package main

import (
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/prometheus/client_golang/prometheus"
)

func TestRoot(t *testing.T) {
	for _, tc := range []struct {
		name, hostname, podIP, nodeIP, want string
	}{
		{"kubernetes", "goapp-test", "10.0.0.2", "172.31.10.1", "Hello, world!\nPod: goapp-test\nPod IP: 10.0.0.2\nNode IP: 172.31.10.1\n"},
		{"local", "", "", "", "Hello, world!\nPod: \nPod IP: \nNode IP: \n"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Setenv("HOSTNAME", tc.hostname)
			t.Setenv("POD_IP", tc.podIP)
			t.Setenv("NODE_IP", tc.nodeIP)
			rec := httptest.NewRecorder()
			router().ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/", nil))
			if rec.Code != http.StatusOK {
				t.Fatalf("status = %d, want 200", rec.Code)
			}
			if got := rec.Header().Get("Content-Type"); got != "text/plain; charset=utf-8" {
				t.Errorf("Content-Type = %q", got)
			}
			if got := rec.Body.String(); got != tc.want {
				t.Errorf("body = %q, want %q", got, tc.want)
			}
		})
	}
}

// Read counts without resetting the shared production registry between tests.
func requestCounts(t *testing.T) (float64, uint64) {
	t.Helper()
	families, err := prometheus.DefaultGatherer.Gather()
	if err != nil {
		t.Fatal(err)
	}
	var requests float64
	var observations uint64
	for _, family := range families {
		for _, metric := range family.GetMetric() {
			switch family.GetName() {
			case "goapp_http_requests_total":
				requests += metric.GetCounter().GetValue()
			case "goapp_http_request_duration_seconds":
				observations += metric.GetHistogram().GetSampleCount()
			}
		}
	}
	return requests, observations
}
func TestMetrics(t *testing.T) {
	srv := httptest.NewServer(router())
	t.Cleanup(srv.Close)
	client := srv.Client()
	beforeRequests, beforeObservations := requestCounts(t)

	resp, err := client.Get(srv.URL + "/")
	if err != nil {
		t.Fatal(err)
	}
	resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("root status = %d", resp.StatusCode)
	}

	resp, err = client.Get(srv.URL + "/metrics")
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("metrics status = %d", resp.StatusCode)
	}
	if !strings.HasPrefix(resp.Header.Get("Content-Type"), "text/plain") {
		t.Errorf("unexpected metrics Content-Type: %q", resp.Header.Get("Content-Type"))
	}
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		t.Fatal(err)
	}
	for _, sample := range []string{
		`goapp_http_requests_total{code="200",method="get"}`,
		`goapp_http_request_duration_seconds_count{method="get"}`,
		"go_goroutines ",
		"process_resident_memory_bytes ",
	} {
		if !strings.Contains(string(body), sample) {
			t.Errorf("metrics missing sample %q", sample)
		}
	}
	afterRequests, afterObservations := requestCounts(t)
	if afterRequests-beforeRequests != 1 {
		t.Errorf("request counter delta = %v, want 1", afterRequests-beforeRequests)
	}
	if afterObservations-beforeObservations != 1 {
		t.Errorf("duration observation delta = %d, want 1", afterObservations-beforeObservations)
	}
}
func TestUnknownRoute(t *testing.T) {
	rec := httptest.NewRecorder()
	router().ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/missing", nil))
	if rec.Code != http.StatusNotFound {
		t.Fatalf("status = %d, want 404", rec.Code)
	}
}
