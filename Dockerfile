FROM alpine:3.21.3

RUN apk add --no-cache make

COPY --from=hashicorp/terraform:1.11 /bin/terraform /bin/terraform
