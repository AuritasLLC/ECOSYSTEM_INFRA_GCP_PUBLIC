# ASM+ Marketplace deployer

This directory builds the ASM+ Standard Kubernetes deployment container. The
image is based on Google's Helm deployer and contains:

- `/data/schema.yaml`, which defines the Marketplace form and image mappings.
- `/data/chart`, which contains the ASM+ Helm chart.
- `/data-test/schema.yaml` and `/data-test/chart`, which provide the automated
  Marketplace verification profile.

Every released image must be a single `linux/amd64` manifest and must include
the ASM+ Marketplace service-name annotation:

```text
com.googleapis.cloudmarketplace.product.service.name=services/asm-plus.endpoints.auritas-asmplus-public.cloud.goog
```

Example build command from the repository root:

```bash
docker buildx build \
  --platform linux/amd64 \
  --provenance=false \
  --sbom=false \
  --output type=docker \
  --tag asmplus-marketplace-deployer:local \
  marketplace/deployer
```

Validate the embedded schema after the image is built:

```bash
docker run --rm --entrypoint /bin/validate_schema.py \
  asmplus-marketplace-deployer:local
```

Publishing and retagging release images is restricted to the Auritas release
process. Do not publish a locally built image as an approved Marketplace
release.
