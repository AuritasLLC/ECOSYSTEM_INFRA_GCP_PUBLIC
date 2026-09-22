# ASM+ Marketplace deployer

This directory builds the ASM+ Standard Kubernetes deployment container. The
image is based on Google's Helm deployer and contains:

- `/data/schema.yaml`, which defines the Marketplace form and image mappings.
- `/data/chart`, which contains the ASM+ Helm chart.
- `/data-test/schema.yaml` and `/data-test/chart`, which provide the automated
  Marketplace verification profile.

Every released image must be a single `linux/amd64` manifest and must include
the service-name annotation assigned to the new Producer Portal product:

```text
com.googleapis.cloudmarketplace.product.service.name=services/<new-listing-service-name>
```

The candidate source deliberately uses `REPLACE_AFTER_NEW_PRODUCT_CREATED`.
Do not publish the deployer until Producer Portal has assigned the exact new
service name and both the schema default and build argument use that value.

Example build command from the repository root:

```bash
docker buildx build \
  --platform linux/amd64 \
  --provenance=false \
  --sbom=false \
  --build-arg RELEASE_VERSION=1.1.0 \
  --build-arg MARKETPLACE_SERVICE_NAME=services/<new-listing-service-name> \
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

The current security assessment and the treatment of vulnerabilities inherited
from the Google deployer runtime are documented in [SECURITY.md](SECURITY.md).
