package main

import (
	"log"
	"net/http"
	"hyperservice-control-app/internal/handler"
)

func main() {
	http.HandleFunc("/", handler.HelloHandler)
	log.Fatal(http.ListenAndServe(":8081", nil))
}