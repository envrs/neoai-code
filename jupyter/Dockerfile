# --- Build Stage ---
FROM golang:1.25-alpine AS builder

WORKDIR /src
# Copy go.mod and go.sum files
COPY go/go.mod go/go.sum ./
# Download dependencies
RUN go mod download

# Copy the source code
COPY go/ ./

# Build the server binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /server ./cmd/server.go


# --- Final Stage ---
FROM python:3.9-alpine

# Copy the binary from the builder stage
COPY --from=builder /server /usr/local/bin/neoai-server

RUN apk add --no-cache build-base && pip install --no-cache-dir python-language-server
RUN chmod 755 /usr/local/bin/neoai-server

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/neoai-server", "-libBaseDir=/usr/local/lib", "-port=8080"]
