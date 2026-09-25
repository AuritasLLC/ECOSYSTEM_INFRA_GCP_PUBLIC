# ASM+ Marketplace release notes

## 1.1.1 (candidate)

- Corrected the ASM+ database migration command for the hardened runtime image.
- Corrected common resource labels so GKE Applications discovers and groups
  the Marketplace deployment components.
- Retained the application image contents validated for version 1.1.0.

## 1.1.0 (private release)

- Updated all eight ASM+ application images to the September 2026 builds
  validated together in the GCP deployment.
- Confirmed all eight public application health endpoints return HTTP 200 with
  valid TLS after the rolling update.
- Staged the exact tested image digests in the producer Artifact Registry.
- Artifact Analysis completed successfully with zero Critical, High, Medium,
  or Low findings for the eight application images.
- Published privately for the replacement `asm-plus-gke` listing and used for
  the first end-to-end customer-style deployment test.

## 1.0.1

- Updated ASM+ API to `dev-41bee4f` to correct public endpoint routing.
- Updated SAP SuccessFactors API to `dev-8b21561` to correct public endpoint routing.
- Retained the existing content of the other eight release images.
- Published the application images and deployer with exact tag `1.0.1` and
  release-track tag `1.0`.
- Recorded the immutable release digests in [`releases/1.0.1.md`](releases/1.0.1.md).

## 1.0.0

- Initial ASM+ BYOL release for Google Kubernetes Engine.
