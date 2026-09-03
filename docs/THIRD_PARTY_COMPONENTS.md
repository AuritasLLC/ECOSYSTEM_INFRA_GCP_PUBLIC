# Third-party components

This inventory documents third-party components directly visible in the ASM+
Marketplace deployment package. It supports, but does not replace, Auritas
legal, security, and open-source compliance review.

## Kubernetes Application CRD

- Project: GoogleCloudPlatform `marketplace-k8s-app-tools` / Kubernetes SIG Apps
- Local path: `marketplace/deployer/chart/ecosystem/crds/application-crd.yaml`
- Upstream path: `crd/app-crd.yaml`
- License header: Apache License 2.0
- Retrieved: 2 September 2026
- Local SHA-256:
  `0b74e3f0d2777bb412c0816aef813b545a4358fd932f42c02ae645f362e82eaa`

## Google Cloud Marketplace Helm deployer

- Base image:
  `gcr.io/cloud-marketplace-tools/k8s/deployer_helm/onbuild`
- Pinned digest:
  `sha256:6a6d705987be9dacb976540b02901250bf09324c2fdc641f64c014da696bd198`
- Purpose: standard Marketplace deployment-container runtime.

## Kubernetes kubectl

- Version built by the deployer Dockerfile: `v1.36.3`
- Upstream project: Kubernetes
- Upstream license: Apache License 2.0

## Helm

- Version built by the deployer Dockerfile: `v4.2.4`
- Upstream project: Helm
- Upstream license: Apache License 2.0

## Go build image

- Image: `golang:1.26.6-bookworm`
- Pinned digest:
  `sha256:116d58cbd88c1297624acc6e967a060012422bacf9930927e23fb719189c6f36`
- Purpose: compile the pinned kubectl and Helm binaries used in the deployer.

## Cloud SQL Auth Proxy

- Purpose: connect ASM+ workloads to the customer-managed Cloud SQL for
  PostgreSQL instance through Workload Identity.
- Upstream project: GoogleCloudPlatform `cloud-sql-proxy`
- Upstream license: Apache License 2.0
- Release image: supplied by Google Cloud Marketplace through the deployer
  image mapping; the chart does not hard-code a customer-visible source tag.

## PostgreSQL client image

- Purpose: run database readiness checks and the authentication schema
  migration.
- Release image: supplied by Google Cloud Marketplace through the deployer
  image mapping.
- Review requirement: the final release SBOM and notices must cover PostgreSQL
  client libraries and all transitive operating-system packages.

## Release control

All third-party and proprietary runtime images are mirrored into the ASM+
producer Artifact Registry, scanned, tagged consistently with the Marketplace
release, and annotated with the Marketplace service name. A source, base-image,
or dependency change requires a new security and license review before release.
