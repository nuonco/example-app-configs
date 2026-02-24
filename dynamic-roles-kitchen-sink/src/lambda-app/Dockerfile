FROM debian:bookworm-slim AS build

ARG GO_VERSION=1.21.13
ARG GO_TARBALL=go${GO_VERSION}.linux-amd64.tar.gz
ARG GO_SHA256=502fc16d5910562461e6a6631fb6377de2322aad7304bf2bcd23500ba9dab4a7

RUN apt-get update && \
    rm -f /etc/ssl/openssl.cnf || true && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN curl -fsSLO https://go.dev/dl/${GO_TARBALL} \
 && echo "${GO_SHA256}  ${GO_TARBALL}" | sha256sum -c -

RUN mkdir -p /opt && tar -C /opt -xzf ${GO_TARBALL} && mv /opt/go /opt/go${GO_VERSION}

ENV GOROOT=/opt/go${GO_VERSION}
ENV GOPATH=/go
ENV PATH=$GOROOT/bin:$GOPATH/bin:$PATH
ENV GOTOOLCHAIN=local
ENV GOEXPERIMENT=
ENV GOFLAGS=
ENV GOPROXY=https://proxy.golang.org,direct
ENV GOMODCACHE=/go/pkg/mod

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .

RUN go version && CGO_ENABLED=0 GOOS=linux go build -o /handler .

FROM alpine:3.19
COPY --from=build /handler /main
ENTRYPOINT ["/main"]
