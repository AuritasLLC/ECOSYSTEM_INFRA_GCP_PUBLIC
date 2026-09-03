# ASM+ Marketplace deployer security assessment

Assessment date: 2026-09-03 UTC

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

The release must also carry the following OCI manifest annotation:

```text
com.googleapis.cloudmarketplace.product.service.name=services/asm-plus.endpoints.auritas-asmplus-public.cloud.goog
```

Artifact Analysis continuously rescans published images. A new image must be
built, tested, scanned, and assigned a new immutable digest whenever updated
packages or a newer compatible Google deployer base become available.
