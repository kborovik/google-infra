FROM alpine:3.21.3

LABEL org.opencontainers.image.source=https://github.com/kborovik/google-infra
LABEL org.opencontainers.image.description="Terraform for GitHub Actions"

RUN apk add --no-cache make

COPY --from=hashicorp/terraform:1.11 /bin/terraform /bin/terraform
