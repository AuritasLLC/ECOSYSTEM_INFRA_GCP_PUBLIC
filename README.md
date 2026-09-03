# ASM+ Google Cloud Marketplace

<p align="center">
  <img src="assets/auritas-logo.png" alt="Auritas logo" height="90" align="middle">
  &nbsp;&nbsp;&nbsp;
  <img src="assets/asm-plus-logo.png" alt="Auritas Storage Manager (ASM+) logo" height="90" align="middle">
</p>

## Overview

Auritas Storage Manager (ASM+) is an enterprise document and content management
solution for SAP environments. It elevates content management performance with
AI-driven analysis, intelligent redaction, metadata management, cross-system
synchronization, and centralized document lifecycle capabilities, including
folder creation, upload, search, viewing, version management, workflows,
notifications, reporting, auditing, and recycle-bin recovery.

ASM Storage API serves as the central content service, while dedicated web
portals and application APIs manage authentication, users, roles, permissions,
documents, and business processes. ASM+ integrates with SAP business
applications through SAP ArchiveLink and with SAP SuccessFactors through
dedicated repository, document management, and authentication APIs.

On Google Cloud, ASM+ is delivered as a customer-hosted Standard Kubernetes
application for an existing customer-managed Google Kubernetes Engine (GKE)
cluster. The application uses Cloud Storage for document content and PostgreSQL
for application metadata, allowing customers to retain control of their
infrastructure, data, networking, security configuration, backups, and cloud
costs.

## Delivery and licensing

The package uses Helm through a Google Cloud Marketplace deployment container.
It installs ASM+ workloads into the GKE cluster and namespace selected by the
customer. It does not use Terraform and does not create a VPC, GKE cluster,
Cloud SQL instance, Cloud Storage bucket, DNS zone, or project IAM policy.

ASM+ is offered under a Bring Your Own License (BYOL) model. Customers obtain
the software entitlement directly from Auritas; Google bills the customer
separately for the Google Cloud resources used by the deployment.

## Documentation

- [Deployment and user guide](docs/USER_GUIDE.md)
- [Security and support](SECURITY.md)
- [Third-party components](docs/THIRD_PARTY_COMPONENTS.md)
- [Marketplace package source](marketplace/README.md)

## Repository layout

- `marketplace/deployer/`: deployer Dockerfile, Marketplace schema, Helm chart,
  Application CRD, and verification test.
- `marketplace/examples/`: non-secret example values.
- `docs/`: customer documentation and third-party component inventory.
- `assets/`: documentation logos.
- `SECURITY.md`: secure support and disclosure guidance.

This repository contains deployment configuration and documentation. It does
not contain ASM+ application source code, credentials, customer data,
Terraform state, or Kubernetes Secret values. The Marketplace release remains
a release candidate until Google completes its review.

The deployment configuration and documentation in this repository are
licensed under the [Apache License 2.0](LICENSE). The ASM+ application software,
container images, trademarks, and commercial license remain proprietary and
are not licensed under this repository's Apache License.
