# Google Cloud Infrastructure Practical Guides

This repository provides practical guidance on building cloud-native infrastructures using DevOps tools and practices that I have found most effective in my daily work.

For detailed descriptions of each guide, please visit [lab5.ca](https://lab5.ca/).

# Deployment Stack

This repository aims to build a **deployment stack** for a Custom Application. The deployment stack comprises three (3) GCP projects, each representing a different environment.

The main goal of the **deployment stack** is to enable **reliable deployments** of the Custom Application to the next environment using GitHub Actions.

We define a **reliable deployment** as achieving at least a 95% success rate for deployments in the production Google Project on the first attempt.

| Google Project | Google Network | GitHub Actions Trigger  |
| -------------- | -------------- | ----------------------- |
| lab5-gcp-dev1  | 10.128.0.0/16  | refs/tags/lab5-gcp-dev1 |
| lab5-gcp-uat1  | 10.129.0.0/16  | refs/tags/lab5-gcp-uat1 |
| lab5-gcp-prd1  | 10.130.0.0/16  | refs/tags/lab5-gcp-prd1 |


# Practical Guides

- [Integrating GitHub Actions with Google Cloud using OpenID Connect](https://lab5.ca/google/github-oidc-gcp/)