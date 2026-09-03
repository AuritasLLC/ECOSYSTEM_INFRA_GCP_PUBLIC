FROM golang:1.26.6-bookworm@sha256:116d58cbd88c1297624acc6e967a060012422bacf9930927e23fb719189c6f36 AS kubectl-builder

RUN git clone --branch v1.36.3 --depth 1 https://github.com/kubernetes/kubernetes.git /src/kubernetes \
    && cd /src/kubernetes \
    && go get golang.org/x/net@v0.57.0 golang.org/x/crypto@v0.55.0 \
    && go mod tidy \
    && go work vendor \
    && make WHAT=cmd/kubectl \
    && install -D -m 0755 _output/bin/kubectl /out/kubectl

FROM golang:1.26.6-bookworm@sha256:116d58cbd88c1297624acc6e967a060012422bacf9930927e23fb719189c6f36 AS helm-builder

RUN git clone --branch v4.2.4 --depth 1 https://github.com/helm/helm.git /src/helm \
    && cd /src/helm \
    && go get oras.land/oras-go/v2@v2.6.2 golang.org/x/net@v0.57.0 golang.org/x/crypto@v0.55.0 \
    && go mod tidy \
    && go mod vendor \
    && make build \
    && install -D -m 0755 bin/helm /out/helm

FROM gcr.io/cloud-marketplace-tools/k8s/deployer_helm/onbuild@sha256:6a6d705987be9dacb976540b02901250bf09324c2fdc641f64c014da696bd198 AS deployer-runtime

# The pinned Google deployer base currently ships kubectl and Helm binaries
# compiled with Go 1.26.5. Rebuild the same tool versions with Go 1.26.6 to
# incorporate the available standard-library security fixes.
COPY --from=kubectl-builder /out/kubectl /opt/kubectl/v1.36/kubectl
COPY --from=helm-builder /out/helm /usr/local/bin/helm

# Apply the current Ubuntu 22.04 security updates available for the pinned
# Google deployer runtime. The deployer does not use pip, setuptools, or wheel
# at runtime, so remove those build-oriented packages while retaining Python
# and PyYAML for schema validation.
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y --no-install-recommends \
    && apt-get purge -y python3-pip python3-setuptools python3-wheel \
    && rm -rf /var/lib/apt/lists/*

# Google Marketplace Verification overlays /data-test on /data. The test
# profile runs one real ASM+ frontend and verifies its in-cluster health
# endpoint without requiring customer Cloud SQL, Cloud Storage, DNS, or
# secrets.
COPY test/schema.yaml /data-test/schema.yaml
COPY test/chart /tmp/asmplus-test-overlay/chart
RUN mkdir -p /data-test/chart \
    && tar -C /tmp/asmplus-test-overlay -czf /data-test/chart/chart.tar.gz chart \
    && rm -rf /tmp/asmplus-test-overlay

# Flatten the patched runtime into a clean final layer. This prevents scanners
# from reporting superseded kubectl, Helm, setuptools, and wheel artifacts that
# remain in lower layers of the upstream image even though they are not
# reachable in the final filesystem.
FROM scratch

COPY --from=deployer-runtime / /

ENV PATH=/opt/kubectl/default:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ENTRYPOINT ["/bin/bash", "/bin/deploy.sh"]

LABEL org.opencontainers.image.title="Auritas Storage Manager (ASM+) Marketplace deployer" \
      org.opencontainers.image.vendor="Auritas LLC" \
      org.opencontainers.image.version="1.0.1" \
      com.googleapis.cloudmarketplace.product.service.name="services/asm-plus.endpoints.auritas-asmplus-public.cloud.goog"
