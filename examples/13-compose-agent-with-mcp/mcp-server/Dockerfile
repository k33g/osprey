FROM --platform=$BUILDPLATFORM golang:1.24.4-alpine AS builder
ARG TARGETOS
ARG TARGETARCH

WORKDIR /app

COPY . .

RUN <<EOF
go mod tidy 
GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build
EOF

#FROM debian:bookworm-slim
FROM scratch
WORKDIR /app
COPY --from=builder /app/mcp-http-server .

EXPOSE 9090

ENTRYPOINT ["./mcp-http-server"]

# docker build --platform linux/arm64 -t osprey-mcp-http-server:demo .
# docker run --rm -p 9090:9090 osprey-mcp-http-server:demo

# http://host.docker.internal:9090/mcp
# curl http://0.0.0.0:5050/mcp
# curl http://0.0.0.0:9090/mcp