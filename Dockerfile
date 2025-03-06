FROM ubuntu:latest

LABEL org.opencontainers.image.source=https://github.com/kborovik/google-infra
LABEL org.opencontainers.image.description="Terraform for GitHub Actions"

RUN apt-get update && apt-get install -y make

COPY --from=hashicorp/terraform:1.11 /bin/terraform /bin/terraform
