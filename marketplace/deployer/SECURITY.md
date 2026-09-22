# ASM+ Marketplace deployer security assessment

Initial assessment: 2026-09-03 UTC

Candidate reassessment: 2026-09-22 UTC

The ASM+ deployer is based on Google's pinned Helm deployer runtime. Before a
release is published, the build applies all security updates currently
available from the Ubuntu 22.04 repositories, removes unused Python packaging
tools, and replaces the inherited kubectl and Helm binaries with versions built
using the patched Go toolchain defined in the Dockerfile.

## Artifact Analysis results

| Finding | Before updates | After updates |
| --- | ---: | ---: |
| Critical | 0 | 0 |
| High | 0 | 0 |
| Medium | 96 | 75 |
| Low | 19 | 11 |
| Minimal | 7 | 7 |
| Total | 122 | 93 |
| Findings with an available fix | 29 | 0 |

The security update removed every finding for which Google Artifact Analysis
reported an available Ubuntu package fix at assessment time. The remaining 93
findings are associated with packages inherited from the pinned Google runtime
and have no applicable package fix reported by Artifact Analysis. They are not
Critical or High severity.

## 1.1.0 candidate reassessment

The `candidate-1.1.0` rebuild applied the Ubuntu security updates available on
2026-09-22 and was rescanned as digest
`sha256:619cfb51ab50a673876c050a8e0abd1937fff1d7554b7b97a3b00c4d5dbc714a`.

| Severity | Findings |
| --- | ---: |
| Critical | 0 |
| High | 0 |
| Medium | 84 |
| Low | 10 |
| Minimal | 7 |
| Total | 101 |
| Findings with an available fix | 0 |

Artifact Analysis continuously updates its vulnerability database, so the
candidate total is not directly comparable to the historical snapshot. The
important release gates remain satisfied: no Critical or High findings and no
available package fixes are being deferred.

The release must also carry the OCI manifest annotation assigned to the new
Producer Portal product:

```text
com.googleapis.cloudmarketplace.product.service.name=services/<new-listing-service-name>
```

Artifact Analysis continuously rescans published images. A new image must be
built, tested, scanned, and assigned a new immutable digest whenever updated
packages or a newer compatible Google deployer base become available.
