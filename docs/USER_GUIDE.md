# ASM+ on Google Cloud: Standard Kubernetes Deployment and User Guide

This guide covers the installation and operation of **Auritas Storage Manager
(ASM+)** as a Google Cloud Marketplace Standard Kubernetes application.

- Publisher: Auritas LLC
- Pricing model: Bring Your Own License (BYOL)
- Support: [Auritas contact page](https://www.auritas.com/contact-us/) or
  `sales@auritas.com`
- Marketplace listing: added here after the Standard Kubernetes product is
  approved and published

## 1. Overview

ASM+ centralizes document storage and access for SAP environments and provides
administration, search, and document-viewing web interfaces. ASM Storage API is
the central application API. Optional workloads connect ASM+ to SAP Business
and SAP SuccessFactors using customer-approved endpoints and credentials.

The Marketplace package installs the ASM+ Kubernetes resources into a GKE
cluster selected by the customer. It does not create Google Cloud
infrastructure with Terraform. The customer retains control of the project,
cluster, database, object storage, networking, secrets, backups, scaling, and
Google Cloud resource costs.

## 2. BYOL license

Customers pay Auritas directly for the ASM+ software license and pay Google
separately for the Google Cloud resources they use. Before deployment, obtain a
license through the license acquisition URL shown on the Marketplace listing.

Auritas must provide the final license format, activation procedure, validation
endpoint, renewal behavior, and failure behavior before release. Never commit a
license value to this repository or pass one in shell history. Store it in a
Kubernetes Secret in the deployment namespace using the procedure supplied with
the approved Marketplace release.

## 3. One-time customer setup

Prepare the following customer-controlled resources:

1. A billing-enabled Google Cloud project.
2. A supported x86-based GKE cluster and `kubectl` access to it.
3. Helm 3 on the administrative workstation if using the CLI installation.
4. The `Application` CRD required by Google Cloud Marketplace.
5. A PostgreSQL database reachable from GKE. Cloud SQL for PostgreSQL is
   recommended for production.
6. A Cloud Storage bucket for ASM+ document content.
7. A Kubernetes service account mapped through Workload Identity to a Google
   service account with the approved bucket permissions.
8. Customer-managed secrets containing the database, JWT, API, initial
   administrator, frontend client, and BYOL license values required by the
   approved release.
9. Customer-managed DNS names and HTTPS certificates for externally exposed
   ASM+ endpoints.
10. Private or public connectivity, as approved by the customer, to any SAP
    Business or SAP SuccessFactors systems being enabled.

The release targets `linux/amd64`. ARM-based GKE nodes are not supported by the
current image set.

Install the Marketplace `Application` CRD once per cluster using the exact CRD
published with the approved release:

```bash
kubectl apply -f marketplace/deployer/chart/ecosystem/crds/application-crd.yaml
kubectl get crd applications.app.k8s.io
```

## 4. Pre-deployment checks

Confirm the active cluster and available capacity:

```bash
kubectl config current-context
kubectl get nodes -o wide
kubectl auth can-i create deployments --namespace "ASMPLUS_NAMESPACE"
kubectl auth can-i create services --namespace "ASMPLUS_NAMESPACE"
```

Confirm that the selected Kubernetes service account exists and is mapped to
the approved Google service account:

```bash
kubectl -n "ASMPLUS_NAMESPACE" get serviceaccount "ASMPLUS_SERVICE_ACCOUNT" -o yaml
```

From an authorized diagnostic Pod or administrative environment, verify that
PostgreSQL is reachable and that the Cloud Storage bucket is accessible. Do not
print credentials or license material in diagnostic output.

## 5. Deploy from Google Cloud Marketplace

After Google approves and publishes the Standard Kubernetes release:

1. Open the ASM+ listing in Google Cloud Marketplace.
2. Acquire or confirm the ASM+ BYOL license through the displayed Auritas URL.
3. Select **Configure** or **Deploy**.
4. Select the customer project, GKE cluster, namespace, and application name.
5. Supply only the non-secret configuration requested by the deployment form.
6. Select the preconfigured Kubernetes service account and the existing Secret
   names required by the release.
7. Review the customer infrastructure charges and deployment summary.
8. Deploy and wait for the deployer, migrations, and application workloads to
   become healthy.

Use only an approved release and the images republished by Google Cloud
Marketplace. Development images and mutable tags are not supported.

## 6. Deploy from the command line

The commands in this section become authoritative only after Google publishes
the release image locations. Clone the repository and check out the exact tag
associated with the Marketplace release:

```bash
git clone https://github.com/AuritasLLC/ECOSYSTEM_INFRA_GCP.git
cd ECOSYSTEM_INFRA_GCP
git checkout "RELEASE_TAG"
```

Create a protected values file from the approved example. Populate only
customer-specific, non-secret values and reference existing Secret and service
account names:

```bash
cp marketplace/examples/values.customer.example.yaml values.customer.yaml
chmod 600 values.customer.yaml
```

Render the chart locally before installation:

```bash
helm lint marketplace/deployer/chart/ecosystem \
  --values values.customer.yaml

helm template "ASMPLUS_RELEASE_NAME" \
  marketplace/deployer/chart/ecosystem \
  --namespace "ASMPLUS_NAMESPACE" \
  --values values.customer.yaml > rendered-asmplus.yaml
```

Inspect the rendered manifests for unexpected namespaces, image sources,
cluster-scoped resources, plaintext credentials, and mutable image references.
Then install the approved chart:

```bash
helm upgrade --install "ASMPLUS_RELEASE_NAME" \
  marketplace/deployer/chart/ecosystem \
  --namespace "ASMPLUS_NAMESPACE" \
  --create-namespace \
  --values values.customer.yaml \
  --wait \
  --timeout 30m
```

Do not use these commands with the pre-release chart until the
[readiness register](MARKETPLACE_READINESS.md) marks the package ready.

## 7. Verify the deployment

```bash
kubectl -n "ASMPLUS_NAMESPACE" get \
  applications.app.k8s.io,pods,services,ingress

kubectl -n "ASMPLUS_NAMESPACE" get pods \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range .status.containerStatuses[*]}{"  "}{.name}{": "}{.imageID}{"\n"}{end}{end}'
```

All required Pods must be `Ready`, migration Jobs must complete, and the
`Application` resource must report the approved version. Every application
image must resolve to the immutable digest republished for that release.

Run the approved functional checks:

1. Sign in through the authentication portal.
2. Confirm that the Documents page loads without a backend error.
3. Upload a non-sensitive test document.
4. Search for it and open it in the document viewer.
5. Delete it and verify the expected recycle-bin behavior.

Use synthetic or customer-approved test content only.

## 8. DNS and TLS

The Standard Kubernetes package does not register customer DNS records. Point
each approved hostname to the ingress address created or selected for the
deployment. Configure TLS using the customer's approved certificate and
ingress process.

Verify DNS, TLS, and application reachability:

```bash
dig +short "APP_HOSTNAME"
kubectl -n "ASMPLUS_NAMESPACE" get ingress
curl --fail --head "https://APP_HOSTNAME/"
```

Do not expose production endpoints over plaintext HTTP.

## 9. Initial access and basic usage

Retrieve the generated or customer-provided initial administrator credential
through the customer's approved secret-management workflow. Sign in, change
the initial password, and confirm the assigned administrator email and roles.

Do not place database passwords, JWT secrets, API keys, frontend client keys,
or BYOL license material in a values file, Git repository, support ticket, or
command line.

## 10. Backup and restore

Back up the PostgreSQL database, Cloud Storage content, required Kubernetes
Secrets, BYOL activation information, DNS/TLS configuration, and the exact
Marketplace release identifier. Use customer-approved retention, encryption,
and access controls.

Test database and object restoration together in a non-production environment.
A database-only or bucket-only backup is not a complete ASM+ recovery set.

## 11. Updates and scaling

For a patch or minor update:

1. Review the release notes and image digests.
2. Test the release in a non-production cluster.
3. Back up the database, document storage, and required Secrets.
4. Update only to the approved Marketplace release.
5. Repeat the readiness, login, upload, search, viewer, and integration tests.

Scale workloads by changing the approved replica and resource values. Scale
Cloud SQL, GKE, and Cloud Storage using the customer's infrastructure process;
those resources are outside the Standard Kubernetes deployment.

## 12. Delete ASM+

Deletion is destructive. First verify restorable backups and determine whether
the customer must retain database records, document objects, Secrets, license
records, DNS entries, or certificates.

Delete the Helm release:

```bash
helm uninstall "ASMPLUS_RELEASE_NAME" --namespace "ASMPLUS_NAMESPACE"
```

Confirm that namespaced application resources are removed. Delete intentionally
retained PersistentVolumeClaims only after separate approval. Customer-owned
Cloud SQL instances, Cloud Storage buckets, IAM bindings, DNS records, and
backups are not deleted by uninstalling the Standard Kubernetes application.

## 13. Support information

For support, provide the Marketplace product and release, customer project ID,
GKE cluster and namespace, approximate failure time and time zone, and sanitized
Kubernetes errors. Never send passwords, tokens, Secret payloads, private keys,
license material, or unredacted customer documents.

Contact [Auritas](https://www.auritas.com/contact-us/) or email
`connect@auritas.com`.
