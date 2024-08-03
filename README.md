# Google Cloud Infrastructure Practical Guides

This repository aims to provide practical content on building Cloud-Native Infrastructures using DevOps tools and practices that I find most effective in my daily work.

For detailed descriptions of each guide, visit [lab5.ca](https://lab5.ca/).

# Deployment Stack

| google_project | google_network | github_actions_trigger  |
| -------------- | -------------- | ----------------------- |
| lab5-gcp-dev1  | 10.128.0.0/16  | refs/tags/lab5-gcp-dev1 |
| lab5-gcp-uat1  | 10.129.0.0/16  | refs/tags/lab5-gcp-uat1 |
| lab5-gcp-prd1  | 10.130.0.0/16  | refs/tags/lab5-gcp-prd1 |

## Practical Guides

- [GitHub Actions and Google Cloud OpenID Connect Integration](https://lab5.ca/google/github-oidc-gcp/)
