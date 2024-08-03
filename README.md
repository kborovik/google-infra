# Google Cloud Infrastructure Examples with Terraform

This repository contains examples of Google Cloud infrastructure deployment for various Google Cloud elements. For detailed descriptions of each example, visit [Lab5.ca](https://www.lab5.ca/).

The main objective is to build a `deployment stack`.

# Deployment Stack

| google_project | google_network | github_actions_trigger  |
| -------------- | -------------- | ----------------------- |
| lab5-gcp-dev1  | 10.128.0.0/16  | refs/tags/lab5-gcp-dev1 |
| lab5-gcp-uat1  | 10.129.0.0/16  | refs/tags/lab5-gcp-uat1 |
| lab5-gcp-prd1  | 10.130.0.0/16  | refs/tags/lab5-gcp-prd1 |

## Practical Guides

- [GitHub Actions and Google Cloud OpenID Connect Integration](https://lab5.ca/google/github-oidc-gcp/)
