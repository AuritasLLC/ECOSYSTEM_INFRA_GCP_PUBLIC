# ASM+ on Google Cloud: Deployment and User Guide

This guide covers Auritas Storage Manager (ASM+) as a Google Cloud Marketplace
Standard Kubernetes application.

- Publisher: Auritas LLC
- Pricing model: Bring Your Own License (BYOL)
- Support: [Auritas contact page](https://www.auritas.com/contact-us/) or
  `connect@auritas.com`
- Release track: `1.0`

## 1. Solution scope

ASM+ centralizes document and content management for SAP environments. The ASM
Storage API is the central content service. The standard installation also
contains authentication, document-management, administration, and document
viewer workloads. SAP Business and SAP SuccessFactors connectors are optional.

The Marketplace package installs Kubernetes resources into an existing GKE
cluster selected by the customer. It does not provision the Google Cloud
project, VPC, GKE cluster, Cloud SQL instance, Cloud Storage bucket, DNS, or IAM
policies. Those resources remain under customer control.

## 2. Licensing

ASM+ uses BYOL. Google does not collect the ASM+ software license fee. Before
deployment, obtain a valid commercial entitlement from Auritas through the
[Auritas contact page](https://www.auritas.com/contact-us/). Google bills the
customer separately for the Google Cloud resources used by the solution.

The deployment form does not request a license key. Auritas provides the
applicable entitlement and activation instructions during customer onboarding.
Do not place licensing material in this repository, a values file, command
history, logs, or a support ticket.

## 3. Customer-managed prerequisites

Prepare the following resources before opening the deployment form:

1. A billing-enabled Google Cloud project.
2. An x86-based GKE cluster with sufficient CPU and memory.
3. A namespace in that cluster, or permission to create one.
4. A PostgreSQL database reachable from GKE. Cloud SQL for PostgreSQL is the
   recommended managed implementation.
5. A Cloud Storage bucket for document content.
6. A Kubernetes service account configured through Workload Identity with
   access to the required Cloud SQL instance and Cloud Storage bucket.
7. A Kubernetes Secret containing the runtime values listed in Section 4.
8. Customer-managed ingress, DNS, and TLS for any externally exposed endpoint.
9. Network connectivity and credentials for each enabled SAP integration.
10. A valid ASM+ BYOL entitlement.

The Helm chart includes the Google Cloud Marketplace `Application` CRD. If the
cluster administrator manages CRDs separately, the exact bundled file is:

```text
marketplace/deployer/chart/ecosystem/crds/application-crd.yaml
```

## 4. Runtime Secret

Create the Secret in the target namespace before deployment. Use an approved
secret-management process; do not commit Secret values to Git.

Required for the core installation:

- `PGPASSWORD`: PostgreSQL password.
- `JWT_SECRET`: signing secret used by the authentication and ASM+ APIs.
- `ASM_API_KEY`: key used for protected communication with ASM Storage API.
- `AUTH_SUPER_ADMIN_PASSWORD`: initial administrator bootstrap password.
- `AUTH_CLIENT_KEY`: authentication client key.

Optional keys:

- `AUTH_CLIENT_KEY_FRONT_AUTH`: separate authentication portal client key.
- `VECTOR_API_KEY`: required only when an approved vector integration is used.
- `SAP_BASIC_AUTH_USERS_JSON`: required when the SAP Business connector is
  enabled.
- `SF_MANAGED_USERS_JSON`: required when the SAP SuccessFactors connector is
  enabled.

Verify only the key names, never their values:

```bash
kubectl -n "ASMPLUS_NAMESPACE" describe secret "ASMPLUS_SECRET_NAME"
```

## 5. Deployment form parameters

The Marketplace form and deployer use the following customer inputs:

| Parameter | Required | Purpose |
| --- | --- | --- |
| Application name | Yes | Prefix used in every ASM+ Kubernetes resource name. |
| Namespace | Yes | Target namespace selected by the customer. |
| Google Cloud project ID | Yes | Project containing the target cluster and customer resources. |
| Google Cloud region | Yes | Region of the customer-managed data services. |
| Existing Cloud Storage bucket | Yes | Bucket used by ASM Storage API for document content. |
| Existing ASM+ Kubernetes Secret | Yes | Name of the pre-created runtime Secret. |
| PostgreSQL user | Yes | Existing database login used through the Cloud SQL Auth Proxy. |
| PostgreSQL database | Yes | Existing database used for ASM+ metadata. |
| Cloud SQL instance connection name | Yes | `PROJECT:REGION:INSTANCE` identifier. |
| ASM+ Kubernetes service account | Yes | Existing Workload Identity-enabled service account. |
| Use Cloud SQL private IP | No | Selects the private IP path; enabled by default. |
| Five core public URLs | Yes | Approved HTTPS URLs for the auth portal, Auth API, ASM+ UI, ASM+ API, and viewer. |
| SAP connector URLs | No | Optional HTTPS URLs used only when those connectors are enabled. |
| Core component toggles | No | Core APIs and frontends are enabled by default. |
| SAP Business connector | No | Optional and disabled by default. |
| SAP SuccessFactors connector | No | Optional and disabled by default. |

Marketplace supplies the approved image locations, deployment-container image,
product service annotation, and consumption-tracking label. Customers do not
enter or change those release-controlled values.

## 6. Pre-deployment checks

Confirm the active cluster and authorization:

```bash
kubectl config current-context
kubectl get nodes -o wide
kubectl auth can-i create deployments --namespace "ASMPLUS_NAMESPACE"
kubectl auth can-i create services --namespace "ASMPLUS_NAMESPACE"
kubectl auth can-i create applications.app.k8s.io --namespace "ASMPLUS_NAMESPACE"
```

Confirm the pre-created service account and Secret exist:

```bash
kubectl -n "ASMPLUS_NAMESPACE" get serviceaccount "ASMPLUS_SERVICE_ACCOUNT"
kubectl -n "ASMPLUS_NAMESPACE" get secret "ASMPLUS_SECRET_NAME"
```

Verify privately that the cluster can reach Cloud SQL and that the mapped
Google service account can access the selected bucket. Do not print credentials
or customer content in diagnostic output.

## 7. Deploy from Google Cloud Marketplace

1. Open the published ASM+ listing in Google Cloud Marketplace.
2. Review the BYOL terms and obtain an ASM+ entitlement from Auritas.
3. Select **Configure** or **Deploy**.
4. Select the customer project, GKE cluster, namespace, and application name.
5. Enter the existing bucket, Secret, Cloud SQL connection name, and Kubernetes
   service account.
6. Enable only the integrations approved for that customer.
7. Review Google Cloud infrastructure charges and the deployment summary.
8. Start the deployment and wait for Marketplace verification to finish.

Use only release images supplied through Google Cloud Marketplace. Development
images and mutable development tags are not supported.

### Command-line deployment

The published Marketplace listing provides a **Deploy via command line** tab.
Select the same project, cluster, namespace, application name, and parameters
described above, then copy the generated command. The generated command supplies
the approved deployment-container image and release-controlled image mappings;
do not replace them with Docker Hub or development image references.

Before running the generated command, configure `gcloud` and `kubectl` for the
customer cluster:

```bash
gcloud config set project "CUSTOMER_PROJECT_ID"
gcloud container clusters get-credentials "GKE_CLUSTER" \
  --region "GKE_REGION" \
  --project "CUSTOMER_PROJECT_ID"
kubectl config current-context
```

Run the exact Marketplace-generated deployment command. Retain the generated
parameter file in the customer's protected change record only if it contains no
Secret values. After installation, confirm that every running container resolves
to an immutable `sha256` image ID as shown in Section 8.

## 8. Validate the installation

The application name prefixes all created resource names. Replace the example
values below with the selections made in the Marketplace form.

```bash
kubectl -n "ASMPLUS_NAMESPACE" get applications.app.k8s.io
kubectl -n "ASMPLUS_NAMESPACE" get deployments,statefulsets,jobs,pods,services
kubectl -n "ASMPLUS_NAMESPACE" get events --sort-by=.lastTimestamp
kubectl -n "ASMPLUS_NAMESPACE" get pods \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range .status.containerStatuses[*]}{"  "}{.name}{": "}{.imageID}{"\n"}{end}{end}'
```

All enabled Deployments must become Available, all required Pods must become
Ready, and migration Jobs must complete successfully. For troubleshooting, use
sanitized output only:

```bash
kubectl -n "ASMPLUS_NAMESPACE" describe application "ASMPLUS_APPLICATION_NAME"
kubectl -n "ASMPLUS_NAMESPACE" get pods \
  -l app.kubernetes.io/instance="ASMPLUS_APPLICATION_NAME"
```

## 9. Network access, DNS, and TLS

The package creates ClusterIP services. The customer is responsible for the
approved ingress or gateway, public or private DNS records, certificates, and
firewall policy. Do not expose production endpoints over plaintext HTTP.

After customer-managed access is configured, validate the following enabled
functions with non-sensitive test data:

1. Sign in through the authentication portal.
2. Load the Documents page without a backend error.
3. Upload a test document.
4. Search for and open the document in the viewer.
5. Verify versioning, deletion, and recycle-bin recovery as applicable.
6. Validate each enabled SAP integration with customer-approved test records.

## 10. Initial administration

Use the customer-approved secret workflow to retrieve the initial administrator
credential. Sign in, replace the bootstrap password immediately, and confirm
the administrator's roles and permissions. Do not copy credentials into a
values file, Git repository, support case, or command line.

## 11. Backup and restore

A complete recovery set includes:

- PostgreSQL data and database configuration.
- Cloud Storage document objects and applicable object versions.
- Required Kubernetes Secret material held in the customer's approved secret
  backup system.
- DNS, TLS, Workload Identity, network, and integration configuration.
- The exact Marketplace release identifier.

Test PostgreSQL and object restoration together in a non-production
environment. A database-only or bucket-only backup is not a complete ASM+
recovery set.

## 12. Scaling and updates

Scale GKE, Cloud SQL, and Cloud Storage through the customer's infrastructure
process. Before an ASM+ update, review release notes, create restorable backups,
test the new Marketplace release in a non-production environment, and repeat the
functional checks in Section 9.

For an approved temporary replica change, use the application-prefixed
Deployment name and record the change so it can be reapplied after an update:

```bash
kubectl -n "ASMPLUS_NAMESPACE" scale deployment \
  "ASMPLUS_APPLICATION_NAME-api-asm-plus" --replicas=2
kubectl -n "ASMPLUS_NAMESPACE" rollout status deployment \
  "ASMPLUS_APPLICATION_NAME-api-asm-plus"
```

Do not edit Marketplace-controlled image references or remove the
`goog-partner-solution` label from Pod templates.

## 13. Uninstall

Uninstalling is destructive to Kubernetes workloads. First confirm backup and
retention requirements. Delete the application through Google Cloud Marketplace
or the supported Helm release workflow used for the installation:

```bash
helm uninstall "ASMPLUS_APPLICATION_NAME" --namespace "ASMPLUS_NAMESPACE"
kubectl -n "ASMPLUS_NAMESPACE" get all \
  -l app.kubernetes.io/instance="ASMPLUS_APPLICATION_NAME"
```

Customer-owned Cloud SQL instances, Cloud Storage buckets, IAM bindings, DNS
records, certificates, backups, and pre-created Secrets are not deleted by the
ASM+ package and must be retained or removed through the customer's own change
process.

## 14. Support

When contacting support, include the Marketplace release, customer project ID,
cluster, namespace, application name, approximate failure time and time zone,
and sanitized Kubernetes errors. Never send passwords, tokens, Secret payloads,
private keys, license material, or unredacted customer documents.

Contact [Auritas](https://www.auritas.com/contact-us/) or email
`connect@auritas.com`.
