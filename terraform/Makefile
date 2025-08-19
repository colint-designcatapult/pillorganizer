# Terraform Makefile for CabiNET Infrastructure

.PHONY: help init plan apply destroy fmt validate clean

# Default environment
ENV ?= staging

help: ## Show this help
	@echo "Available targets:"
	@echo ""
	@echo "Environment Management:"
	@echo "  make staging-plan     - Plan staging environment"
	@echo "  make staging-apply    - Apply staging environment"
	@echo "  make staging-destroy  - Destroy staging environment"
	@echo "  make production-plan  - Plan production environment"
	@echo "  make production-apply - Apply production environment"
	@echo "  make production-destroy - Destroy production environment"
	@echo ""
	@echo "Workspaces:"
	@echo "  make workspace-create ENV=staging|production - Create workspace"
	@echo "  make workspace-select ENV=staging|production - Select workspace"
	@echo "  make workspace-list   - List workspaces"
	@echo ""
	@echo "Other targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

init: ## Initialize Terraform
	terraform init

# Staging Environment
staging-plan: ## Plan staging environment
	terraform workspace select staging || terraform workspace new staging
	terraform plan -var-file="terraform.staging.tfvars"

staging-apply: ## Apply staging environment
	terraform workspace select staging || terraform workspace new staging
	terraform apply -var-file="terraform.staging.tfvars"

staging-destroy: ## Destroy staging environment
	terraform workspace select staging
	terraform destroy -var-file="terraform.staging.tfvars"

staging-output: ## Show staging outputs
	terraform workspace select staging
	terraform output

# Production Environment
production-plan: ## Plan production environment
	terraform workspace select production || terraform workspace new production
	terraform plan -var-file="terraform.production.tfvars"

production-apply: ## Apply production environment
	terraform workspace select production || terraform workspace new production
	terraform apply -var-file="terraform.production.tfvars"

production-destroy: ## Destroy production environment
	terraform workspace select production
	terraform destroy -var-file="terraform.production.tfvars"

production-output: ## Show production outputs
	terraform workspace select production
	terraform output

# Workspace Management
workspace-create: ## Create workspace (usage: make workspace-create ENV=staging)
	terraform workspace new $(ENV)

workspace-select: ## Select workspace (usage: make workspace-select ENV=staging)
	terraform workspace select $(ENV)

workspace-list: ## List all workspaces
	terraform workspace list

workspace-show: ## Show current workspace
	terraform workspace show

# Generic targets (use current workspace)
plan: ## Create Terraform plan for current workspace
	@echo "Planning for workspace: $$(terraform workspace show)"
	@if [ "$$(terraform workspace show)" = "staging" ]; then \
		terraform plan -var-file="terraform.staging.tfvars"; \
	elif [ "$$(terraform workspace show)" = "production" ]; then \
		terraform plan -var-file="terraform.production.tfvars"; \
	else \
		echo "Unknown workspace. Please use staging or production workspace."; \
		exit 1; \
	fi

apply: ## Apply Terraform configuration for current workspace
	@echo "Applying for workspace: $$(terraform workspace show)"
	@if [ "$$(terraform workspace show)" = "staging" ]; then \
		terraform apply -var-file="terraform.staging.tfvars"; \
	elif [ "$$(terraform workspace show)" = "production" ]; then \
		terraform apply -var-file="terraform.production.tfvars"; \
	else \
		echo "Unknown workspace. Please use staging or production workspace."; \
		exit 1; \
	fi

destroy: ## Destroy Terraform infrastructure for current workspace
	@echo "Destroying workspace: $$(terraform workspace show)"
	@if [ "$$(terraform workspace show)" = "staging" ]; then \
		terraform destroy -var-file="terraform.staging.tfvars"; \
	elif [ "$$(terraform workspace show)" = "production" ]; then \
		terraform destroy -var-file="terraform.production.tfvars"; \
	else \
		echo "Unknown workspace. Please use staging or production workspace."; \
		exit 1; \
	fi

fmt: ## Format Terraform files
	terraform fmt -recursive

validate: ## Validate Terraform configuration
	terraform validate

clean: ## Clean Terraform cache and state backups
	rm -rf .terraform
	rm -f *.tfstate.backup
	rm -f .terraform.lock.hcl

check: fmt validate ## Format and validate Terraform files

setup: ## Setup environment tfvars files
	@if [ ! -f terraform.staging.tfvars ]; then \
		echo "terraform.staging.tfvars already exists."; \
	fi
	@if [ ! -f terraform.production.tfvars ]; then \
		echo "terraform.production.tfvars already exists."; \
	fi
	@echo "Edit terraform.staging.tfvars and terraform.production.tfvars with your values."

output: ## Show Terraform outputs for current workspace
	terraform output

state-list: ## List Terraform state resources
	terraform state list

refresh: ## Refresh Terraform state for current workspace
	@if [ "$$(terraform workspace show)" = "staging" ]; then \
		terraform refresh -var-file="terraform.staging.tfvars"; \
	elif [ "$$(terraform workspace show)" = "production" ]; then \
		terraform refresh -var-file="terraform.production.tfvars"; \
	else \
		echo "Unknown workspace. Please use staging or production workspace."; \
		exit 1; \
	fi

import: ## Import existing AWS resource (usage: make import RESOURCE=aws_instance.example ID=i-1234567890abcdef0)
	terraform import $(RESOURCE) $(ID)