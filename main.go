package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gorilla/mux"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	httpRequests = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "goapp_http_requests_total",
			Help: "Total application HTTP requests.",
		},
		[]string{"code", "method"},
	)

	httpDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "goapp_http_request_duration_seconds",
			Help:    "Application HTTP request duration.",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method"},
	)
)

func init() {
	prometheus.MustRegister(httpRequests, httpDuration)
}

func handler(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")

	fmt.Fprintf(w, "Hello, world!\nPod: %s\nPod IP: %s\nNode IP: %s\n",
		os.Getenv("HOSTNAME"),
		os.Getenv("POD_IP"),
		os.Getenv("NODE_IP"),
	)
}

func router() *mux.Router {
	r := mux.NewRouter()

	appHandler := promhttp.InstrumentHandlerCounter(
		httpRequests,
		promhttp.InstrumentHandlerDuration(
			httpDuration,
			http.HandlerFunc(handler),
		),
	)

	r.Handle("/", appHandler)
	r.Handle("/metrics", promhttp.Handler())

	return r
}

func main() {
	srv := &http.Server{
		Handler:      router(),
		Addr:         "0.0.0.0:8080",
		WriteTimeout: 15 * time.Second,
		ReadTimeout:  15 * time.Second,
	}

	log.Fatal(srv.ListenAndServe())
}
