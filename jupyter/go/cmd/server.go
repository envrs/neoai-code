package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/neopilot-ai/neoai-code/jupyter/go/pkg/neoai"
)

func main() {
	var libBaseDir string
	var port int

	flag.StringVar(&libBaseDir, "libBaseDir", "./", "base directory of neoai binaries")
	flag.IntVar(&port, "port", 9999, "Server port")
	flag.Parse()

	tn, err := neoai.NewNeoAi(libBaseDir)
	if err != nil {
		log.Fatalf("Failed to initialize NeoAi: %v", err)
	}
	defer tn.Close()

	mux := http.NewServeMux()
	mux.HandleFunc("/neoai", neoaiHandler(tn))

	server := &http.Server{
		Addr:    fmt.Sprintf(":%d", port),
		Handler: loggingMiddleware(mux),
	}

	// Graceful shutdown
	idleConnsClosed := make(chan struct{})
	go func() {
		sigint := make(chan os.Signal, 1)
		signal.Notify(sigint, os.Interrupt, syscall.SIGTERM)
		<-sigint

		log.Println("Shutdown signal received, shutting down server...")

		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		if err := server.Shutdown(ctx); err != nil {
			log.Printf("HTTP server shutdown error: %v", err)
		}
		close(idleConnsClosed)
	}()

	log.Printf("Starting server on port %d", port)
	if err := server.ListenAndServe(); err != http.ErrServerClosed {
		log.Fatalf("HTTP server ListenAndServe error: %v", err)
	}

	<-idleConnsClosed
	log.Println("Server stopped.")
}

func neoaiHandler(tn *neoai.NeoAi) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Set CORS header
		w.Header().Set("Access-Control-Allow-Origin", "*")

		if r.Method != http.MethodGet {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		data := r.URL.Query().Get("data")
		if data == "" {
			http.Error(w, "Missing 'data' query parameter", http.StatusBadRequest)
			return
		}

		responseBytes := tn.Request([]byte(data))
		w.Header().Set("Content-Type", "application/json")
		w.Write(responseBytes)
	}
}

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		next.ServeHTTP(w, r)
		log.Printf("%s %s %s", r.Method, r.RequestURI, time.Since(start))
	})
}
