.EXPORT_ALL_VARIABLES:
.ONESHELL:
.SILENT:

MAKEFLAGS += --no-builtin-rules --no-builtin-variables

###############################################################################
# Variables
###############################################################################

google_project ?= lab5-gcp-dev1

###############################################################################
# Settings
###############################################################################

app_id := gcp

root_dir := $(abspath .)

terraform_dir := $(root_dir)/terraform
terraform_config := $(root_dir)/config/$(google_project)
terraform_tfvars := $(terraform_config)/terraform.tfvars
terraform_output := $(terraform_config)/$(google_project).json
terraform_bucket := terraform-$(google_project)
terraform_prefix := $(app_id)

ifeq ($(wildcard $(terraform_tfvars)),)
  $(error ==> Missing configuration file $(terraform_tfvars) <==)
endif

VERSION := $(file < VERSION)

###############################################################################
# Info
###############################################################################

default: settings

help:
	$(call header,Help)
	$(call help,make google,Configure Google CLI)
	$(call help,make google-auth,Authenticate Google CLI)
	$(call help,make terraform,Run Terraform plan and apply)
	$(call help,make shutdown,Remove selected Terraform resources)
	$(call help,make release,Trigger GitHub pipeline deployment)

settings: terraform-config
	$(call header,Settings)
	$(call var,google_project,$(google_project))
	$(call var,gcloud_project,$(shell gcloud config list --format=json | jq -r '.core.project'))

secretes:
	$(call header,Secrets)

###############################################################################
# End-to-End Pipeline
###############################################################################

deploy : terraform

shutdown: 
	google_project=lab5-gcp-dev1 $(MAKE) terraform-destroy-selected
	google_project=lab5-gcp-uat1 $(MAKE) terraform-destroy-selected
	google_project=lab5-gcp-prd1 $(MAKE) terraform-destroy-selected

clean: terraform-clean kube-clean

lab5-gcp-dev1:
	google_project=$(@) $(MAKE) terraform

lab5-gcp-uat1:
	google_project=$(@) $(MAKE) terraform

lab5-gcp-prd1:
	google_project=$(@) $(MAKE) terraform

###############################################################################
# Terraform
###############################################################################

.PHONY: terraform

terraform: terraform-plan prompt terraform-apply

terraform-fmt: terraform-version
	$(call header,Check Terraform Code Format)
	cd $(terraform_dir)
	terraform fmt -check -recursive

terraform-config:
	ln -rfs $(terraform_tfvars) $(terraform_dir)/terraform.tfvars

terraform-validate:
	$(call header,Validate Terraform)
	cd $(terraform_dir)
	terraform validate

terraform-init: terraform-fmt terraform-config
	$(call header,Initialize Terraform)
	cd $(terraform_dir)
	terraform init -upgrade -input=false -reconfigure -backend-config="bucket=$(terraform_bucket)" -backend-config="prefix=$(terraform_prefix)"

terraform-plan: terraform-init terraform-validate
	$(call header,Run Terraform Plan)
	cd $(terraform_dir)
	terraform plan -input=false -refresh=true -var-file="$(terraform_tfvars)"

terraform-apply: terraform-init terraform-validate
	$(call header,Run Terraform Apply)
	set -e
	cd $(terraform_dir)
	terraform apply -auto-approve -input=false -refresh=true -var-file="$(terraform_tfvars)"

terraform-destroy-all: terraform-init
	$(call header,Run Terraform Apply)
	cd $(terraform_dir)
	terraform apply -destroy -input=false -refresh=true -var-file="$(terraform_tfvars)"

terraform-destroy-selected: terraform-init
	$(call header,Run Terraform Apply)
	cd $(terraform_dir)
	terraform apply -auto-approve -destroy -var-file="$(terraform_tfvars)" \
	-target=google_compute_address.cloud_nat \
	-target=google_container_cluster.gke1

terraform-clean:
	$(call header,Delete Terraform providers and state)
	-rm -rf $(terraform_dir)/.terraform

terraform-show:
	cd $(terraform_dir)
	terraform show -no-color | bat -l hcl

terraform-version:
	$(call header,Terraform Version)
	terraform version

terraform-state-list:
	cd $(terraform_dir)
	terraform state list

terraform-state-recursive:
	gsutil ls -r gs://$(terraform_bucket)/**

terraform-state-versions:
	gsutil ls -a gs://$(terraform_bucket)/$(terraform_prefix)/default.tfstate

terraform-state-unlock:
	gsutil rm gs://$(terraform_bucket)/$(terraform_prefix)/default.tflock

terraform-bucket:
	$(call header,Create Terrafomr state GCS bucket)
	set -e
	gsutil mb -p $(google_project) -l $(google_region) -b on gs://$(terraform_bucket) || true
	gsutil ubla set on gs://$(terraform_bucket)
	gsutil versioning set on gs://$(terraform_bucket)

###############################################################################
# Google CLI
###############################################################################

google_region := $(shell grep google_region $(terraform_tfvars) | cut -d '"' -f2)

google: google-config

google-auth:
	$(call header,Configure Google CLI)
	gcloud auth revoke --all
	gcloud auth login --update-adc --no-launch-browser

google-config:
	set -e
	gcloud auth application-default set-quota-project $(google_project)
	gcloud config set core/project $(google_project)
	gcloud config set compute/region $(google_region)
	gcloud config list

google-project:
	$(call header,Create Google Project)
	$(eval google_organization := $(shell pass lab5/google/organization_id))
	$(eval google_billing_account := $(shell pass lab5/google/billing_account))
	set -e
	gcloud projects create $(google_project) --organization=$(google_organization)
	gcloud billing projects link $(google_project) --billing-account=$(google_billing_account)
	gcloud services enable cloudresourcemanager.googleapis.com --project=$(google_project)
	gcloud services enable compute.googleapis.com --project=$(google_project)

###############################################################################
# Kubernetes (GKE)
###############################################################################

KUBECONFIG ?= $(HOME)/.kube/config

kube: kube-clean kube-auth kube-info

kube-auth: $(KUBECONFIG)

$(KUBECONFIG):
	$(call header,Get Kubernetes credentials)
	gcloud container clusters get-credentials --zone=us-central1 --project=$(google_project) gke-0
	gcloud container clusters get-credentials --zone=us-east1 --project=$(google_project) gke-1

kube-info:
	$(call header,Get Kubernetes cluster info)
	kubectl cluster-info

kube-clean:
	$(call header,Delete Kubernetes credentials)
	rm -rf $(KUBECONFIG)

###############################################################################
# Repo Version
###############################################################################

commit:
	version=$$(date +%Y.%m.%d-%H%M)
	git add --all
	git commit -m "$$version"

release:
	$(if $(shell git diff --name-only --exit-code),$(error ==> make version <==),)
	$(if $(shell git diff --staged --name-only --exit-code),$(error ==> make commit <==),)
	$(eval git_current_branch := $(shell git branch --show-current))
	$(if $(shell git diff --name-only --exit-code $(git_current_branch) origin/$(git_current_branch)),$(error ==> git push <==),)
	echo -n "$(blue)GitHub deploy $(yellow)$(google_project)$(reset)? $(green)(yes/no)$(reset)"
	read -p ": " answer && [ "$$answer" = "yes" ] || exit 1
	git tag --force $(google_project) -m "$(google_project)"
	git push --force --tags

###############################################################################
# Colors and Headers
###############################################################################

TERM := xterm-256color

black := $$(tput setaf 0)
red := $$(tput setaf 1)
green := $$(tput setaf 2)
yellow := $$(tput setaf 3)
blue := $$(tput setaf 4)
magenta := $$(tput setaf 5)
cyan := $$(tput setaf 6)
white := $$(tput setaf 7)
reset := $$(tput sgr0)

define header
echo "$(blue)==> $(1) <==$(reset)"
endef

define help
echo "$(green)$(1)$(reset) - $(white)$(2)$(reset)"
endef

define var
echo "$(magenta)$(1)$(reset)=$(yellow)$(2)$(reset)"
endef

prompt:
	echo -n "$(blue)Deploy $(yellow)$(google_project)? $(green)(yes/no)$(reset)"
	read -p ": " answer && [ "$$answer" = "yes" ] || exit 1
