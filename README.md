# Google Cloud Infrastructure Practical Guides

This repository provides practical guidance on building cloud-native infrastructures using DevOps tools and practices that I have found most effective in my daily work.

For detailed descriptions of each guide, please visit [lab5.ca](https://lab5.ca/).

## Deployment Stack Overview

The primary focus of this repository is to construct a **deployment stack** for a Custom Application. This stack consists of three Google Cloud Platform (GCP) projects, each representing a distinct environment.

### Key Objectives

1. Enable **reliable deployments** of the Custom Application across environments using GitHub Actions.
2. Achieve a minimum 95% success rate for first-attempt deployments in the production Google Project.

### Environment Configuration

| Google Project | Network Range | GitHub Actions Trigger  |
| -------------- | ------------- | ----------------------- |
| lab5-gcp-dev1  | 10.128.0.0/16 | refs/tags/lab5-gcp-dev1 |
| lab5-gcp-uat1  | 10.129.0.0/16 | refs/tags/lab5-gcp-uat1 |
| lab5-gcp-prd1  | 10.130.0.0/16 | refs/tags/lab5-gcp-prd1 |

## Available Practical Guides

[Integrating GitHub Actions with Google Cloud using OpenID Connect](https://lab5.ca/google/github/)

This guide provides step-by-step instructions on securely connecting GitHub Actions to Google Cloud services using OpenID Connect (OIDC) authentication.

[Google Kubernetes Engine (GKE) Autopilot Cluster Mode](https://lab5.ca/google/gke-autopilot/)

GKE Autopilot enables cost-effective, isolated development environments for cloud-native applications, offering automated management, enhanced security, and optimized resource allocation with reduced Kubernetes cluster administration.