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

app_id := gkekms

root_dir := $(abspath .)

terraform_config := $(root_dir)/config/$(google_project)
terraform_tfvars := $(terraform_config)/terraform.tfvars
terraform_output := $(terraform_config)/$(google_project).json
terraform_bucket := terraform-$(google_project)
terraform_prefix := $(app_id)

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

clean: terraform-clean ## Remove Terraform and Kubernetes configuration

###############################################################################
# Terraform
###############################################################################

.PHONY: terraform

terraform: terraform-plan prompt terraform-apply ## Terraform Plan and Apply

terraform-fmt:
	$(call header,Check Terraform Code Format)
	terraform version
	terraform fmt -check -recursive

terraform-config:

terraform-validate:
	$(call header,Validate Terraform)
	terraform validate

terraform-init: terraform-fmt terraform-config
	$(call header,Initialize Terraform)
	terraform init -upgrade -input=false -reconfigure -backend-config="bucket=$(terraform_bucket)" -backend-config="prefix=$(terraform_prefix)"

terraform-plan: terraform-init terraform-validate ## Terraform Plan
	$(call header,Run Terraform Plan)
	terraform plan -input=false -refresh=true

terraform-apply: terraform-init terraform-validate ## Terraform Apply
	$(call header,Run Terraform Apply)
	set -e
	terraform apply -auto-approve -input=false -refresh=true

terraform-destroy: terraform-init ## Terraform Destroy
	$(call header,Run Terraform Apply)
	terraform apply -destroy -input=false -refresh=true

terraform-clean:
	$(call header,Delete Terraform providers and state)
	-rm -rf .terraform .terraform.lock.hcl

terraform-show: ## Terraform Show State
	terraform show -no-color | bat -l hcl

terraform-list: ## Terraform List State
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
# Repo Version
###############################################################################

commit: ## Commit Changes
	git commit -m "$(shell date +%Y.%m.%d-%H%M)"

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
