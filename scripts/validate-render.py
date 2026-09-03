#!/usr/bin/env python3
"""Validate rendered ASM+ manifests for Marketplace packaging requirements."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys

import yaml


CONSUMPTION_LABEL = (
    "isol_plb32_0014m00001irgbqqaq_g4sz646dffwwygzqyiappxoc7q5x4tjk"
)
POD_CONTROLLERS = {"Deployment", "StatefulSet", "Job"}
REQUIRED_RESOURCES = {"cpu", "memory", "ephemeral-storage"}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--release", required=True)
    args = parser.parse_args()

    documents = [
        item
        for item in yaml.safe_load_all(args.manifest.read_text(encoding="utf-8-sig"))
        if item
    ]
    controllers = [item for item in documents if item.get("kind") in POD_CONTROLLERS]
    errors: list[str] = []

    for item in documents:
        kind = item.get("kind", "unknown")
        name = item.get("metadata", {}).get("name", "")
        if kind != "CustomResourceDefinition" and not name.startswith(args.release):
            errors.append(f"{kind}/{name}: resource name lacks the deployment prefix")

    for item in controllers:
        pod = item["spec"]["template"]
        name = item["metadata"]["name"]
        labels = pod.get("metadata", {}).get("labels", {})
        if labels.get("goog-partner-solution") != CONSUMPTION_LABEL:
            errors.append(f"{item['kind']}/{name}: consumption label is missing")

        pod_spec = pod["spec"]
        containers = pod_spec.get("initContainers", []) + pod_spec.get("containers", [])
        for container in containers:
            resources = container.get("resources", {})
            for side in ("requests", "limits"):
                present = set(resources.get(side, {}))
                missing = REQUIRED_RESOURCES - present
                if missing:
                    errors.append(
                        f"{item['kind']}/{name}/{container['name']}: "
                        f"missing {side}: {', '.join(sorted(missing))}"
                    )

    print(
        f"documents={len(documents)} controllers={len(controllers)} "
        f"errors={len(errors)}"
    )
    for error in errors:
        print(error)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
