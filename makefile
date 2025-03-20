.EXPORT_ALL_VARIABLES:
.ONESHELL:
.SILENT:

MAKEFLAGS += --no-builtin-rules --no-builtin-variables

default: help

###############################################################################
# Variables
###############################################################################

google_project ?= lab5-gcp-uat1

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

###############################################################################
# Info
###############################################################################

settings: terraform-config
	$(call header,Settings)
	$(call var,google_project,$(google_project))
	$(call var,gcloud_project,$(shell gcloud config list --format=json | jq -r '.core.project'))

###############################################################################
# End-to-End Pipeline
###############################################################################

clean: terraform-clean kube-clean ## Remove Terraform and Kubernetes configuration

shutdown: ## Destroy all GCP resources
	google_project=lab5-gcp-dev1 $(MAKE) terraform-destroy
	google_project=lab5-gcp-uat1 $(MAKE) terraform-destroy
	google_project=lab5-gcp-prd1 $(MAKE) terraform-destroy

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

terraform: terraform-plan prompt terraform-apply ## Terraform Plan and Apply

terraform-fmt:
	$(call header,Check Terraform Code Format)
	cd $(terraform_dir)
	terraform version
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

terraform-plan: terraform-init terraform-validate ## Terraform Plan
	$(call header,Run Terraform Plan)
	cd $(terraform_dir)
	terraform plan -input=false -refresh=true -var-file="$(terraform_tfvars)"

terraform-apply: terraform-init terraform-validate ## Terraform Apply
	$(call header,Run Terraform Apply)
	set -e
	cd $(terraform_dir)
	terraform apply -auto-approve -input=false -refresh=true -var-file="$(terraform_tfvars)"

terraform-destroy: terraform-init ## Terraform Destroy
	$(call header,Run Terraform Apply)
	cd $(terraform_dir)
	terraform apply -destroy -input=false -refresh=true -var-file="$(terraform_tfvars)"

terraform-clean:
	$(call header,Delete Terraform providers and state)
	-rm -rf $(terraform_dir)/.terraform

terraform-show: ## Terraform Show State
	cd $(terraform_dir)
	terraform show -no-color | bat -l hcl

terraform-list: ## Terraform List State
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

google-auth: ## Google CLI Auth
	$(call header,Configure Google CLI)
	gcloud auth revoke --all
	gcloud auth login --update-adc --no-launch-browser

google-config: ## Google CLI Config
	set -e
	gcloud auth application-default set-quota-project $(google_project)
	gcloud config set core/project $(google_project)
	gcloud config set compute/region $(google_region)
	gcloud config list

google-project: ## Create Google Project
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

kube-auth: $(KUBECONFIG) ## Kubernetes Auth

$(KUBECONFIG):
	$(call header,Get Kubernetes credentials)
	gcloud container clusters get-credentials --zone=us-central1 --project=$(google_project) gke-0
	gcloud container clusters get-credentials --zone=us-east1 --project=$(google_project) gke-1

kube-info: ## Kubernetes Info
	$(call header,Get Kubernetes cluster info)
	kubectl cluster-info

kube-clean: ## Kubernetes Clean
	$(call header,Delete Kubernetes credentials)
	rm -rf $(KUBECONFIG)

###############################################################################
# Repo Version
###############################################################################

commit: ## Commit Changes
	git commit -m "$(shell date +%Y.%m.%d-%H%M)"

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

define var
echo "$(magenta)$(1)$(white): $(yellow)$(2)$(reset)"
endef

help:
	echo "$(blue)Usage: $(green)make [recipe]$(reset)"
	echo "$(blue)Recipes:$(reset)"
	awk 'BEGIN {FS = ":.*?## "; sort_cmd = "sort"} /^[a-zA-Z0-9_-]+:.*?## / \
	{ printf "  \033[33m%-17s\033[0m %s\n", $$1, $$2 | sort_cmd; } \
	END {close(sort_cmd)}' $(MAKEFILE_LIST)

prompt:
	printf "$(magenta)Continue $(white)? $(cyan)(yes/no)$(reset)"
	read -p ": " answer && [ "$$answer" = "yes" ] || exit 127
