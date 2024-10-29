# Pulumi Customer Managed Deployment Agent

This repository contains the release artifacts for Customer Managed Deployment Agents.

See https://www.pulumi.com/docs/pulumi-cloud/deployments/ for additional details about this product.

## Verifying release artifacts

### Checksum signature

This command requires [cosign](https://docs.sigstore.dev/system_config/installation/) to be installed.

Run the following command to verify the signature of the release checksums:

```bash
cosign verify-blob \
  --key <path to cosign.pub> \
  --signature checksums.txt.sig \
  checksums.txt
```

If the signature validates, you will see the following message:

```bash
Verified OK
```

### Checksums

You can validate the file checksums by running the following command:

```bash
sha256sum --ignore-missing -c checksums.txt
```

If the checksums match the downloaded files, you will see output like this:

```bash
customer-managed-deployment-agent_1.0.0_darwin_amd64.tar.gz: OK
customer-managed-deployment-agent_1.0.0_darwin_arm64.tar.gz: OK
customer-managed-deployment-agent_1.0.0_linux_amd64.tar.gz: OK
customer-managed-deployment-agent_1.0.0_linux_arm64.tar.gz: OK
```
