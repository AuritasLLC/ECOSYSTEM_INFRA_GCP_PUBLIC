# ASM+ Standard Kubernetes package

This directory contains the public configuration used to build and review the
ASM+ Google Cloud Marketplace Standard Kubernetes package.

## Contents

- `deployer/Dockerfile`: builds the Google Marketplace Helm deployer.
- `deployer/schema.yaml`: Marketplace deployment schema and image mappings.
- `deployer/chart/ecosystem/`: ASM+ Helm chart and bundled Application CRD.
- `deployer/test/`: Marketplace verification overlay and health test.
- `examples/values.customer.example.yaml`: non-secret values example for local
  rendering and review.

The deployer installs application resources into an existing customer-selected
GKE cluster and namespace. It does not provision infrastructure with Terraform.
All runtime images are parameterized so Google Cloud Marketplace can substitute
the reviewed Artifact Registry images.

## Local validation

From the repository root:

```bash
helm lint marketplace/deployer/chart/ecosystem \
  --values marketplace/examples/values.customer.example.yaml

helm template asm-plus-review marketplace/deployer/chart/ecosystem \
  --namespace asm-plus-review \
  --values marketplace/examples/values.customer.example.yaml \
  > rendered-asmplus.yaml
```

The example uses placeholders instead of deployable image references and never
contains Secret values. Deployment is supported through the approved Google
Cloud Marketplace release.
