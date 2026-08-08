import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

infra_dir = "../infrastructure"
files = [
    "gcp-network.tf",
    "gcp-security.tf",
    "gcp-workload.tf",
    "aws-network.tf",
    "aws-security.tf",
    "aws-workload.tf",
    "vpn.tf",
    "identity.tf",
    "outputs.tf",
    "variables.tf",
    "locals.tf"
]

print("Scanning local Terraform files:")
for f in files:
    path = os.path.join(infra_dir, f)
    if os.path.exists(path):
        lines = open(path, "r", encoding="utf-8").readlines()
        print(f"- {f}: size={os.path.getsize(path)} bytes, lines={len(lines)}")
    else:
        print(f"- {f}: NOT FOUND")
