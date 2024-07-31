# Google Cloud Infrastructure Examples with Terraform

This repository contains Google Cloud infrastructure deployment examples for various Google Cloud elements. For detailed descriptions of each example, visit [https://www.lab5.ca/](https://www.lab5.ca/)

## Topics

- [GitHub Actions and Google Cloud OpenID Connect Integration](https://lab5.ca/google/github-oidc-gcp/)

## Security Static Analysis

We use [Checkov](https://www.checkov.io/), a static code analysis tool, to scan our infrastructure as code (IaC) files for potential security misconfigurations or compliance issues.

To run the security analysis:

```shell
make checkov
```

## Terraform

To apply the Terraform configuration:

```shell
make terraform
```
