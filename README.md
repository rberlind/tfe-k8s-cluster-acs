# Kubernetes in Legacy Azure Container Service (ACS)
Terraform configuration for deploying Kubernetes in the [legacy Azure Container Service (ACS)](https://docs.microsoft.com/en-us/azure/container-service/kubernetes/).

## Introduction
This Terraform configuration replicates what an Azure customer could do with the `az acs create` [CLI command](https://docs.microsoft.com/en-us/cli/azure/acs?view=azure-cli-latest#az_acs_create). It uses the Microsoft AzureRM provider's azurerm_container_service resource to create an entire Kubernetes cluster in ACS including required VMs, networks, and other Azure constructs. Note that this creates a legacy ACS service which includes both the master node VMs that run the Kubernetes control plane and the agent node VMs onto which customers deploy their containerized applications. This differs from the  [new Azure Container Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/) which excludes the master node VMs since Microsoft runs those outside the customer's Azure account.

## Deployment Prerequisites

1. Sign up for a free [Azure account](https://azure.microsoft.com/en-us/free/).
1. Install [Azure CLI 2.0](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
1. Configure the Azure CLI for your account and generate a Service Principal for Kubernetes to use when interacting with the Azure Resource Manager. See these [instructions](https://www.terraform.io/docs/providers/azurerm/authenticating_via_service_principal.html). If you only have a single subscription in your Azure account, this just involves running `az login` and following the prompts, running `az account list`, and running `az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<SUBSCRIPTION_ID>"` where \<SUBSCRIPTION_ID\> is the id returned by the `az account list` command.
1. Create a copy of k8s.tfvars.example called k8s.tfvars and set azure_client_id and azure_client_secret to the service principal's appID and password respectively. Set azure_subscription_id in k8s.tfvars to your subscription ID and set azure_tenant_id to the tenant ID of your service principal.
1. Set dns_master_prefix and dns_agent_pool_prefix in k8s.tfvars to strings that you would like Azure to use as the DNS prefixes for the master and agent nodes in your Kubernetes cluster.

## Deployment Steps
Execute the following commands to deploy your Kubernetes cluster to ACS.

1. Run `terraform init` to initialize your terraform-acs-engine configuration.
1. Run `terraform plan -var-file="k8s.tfvars"` to do a Terraform plan.
1. Run `terraform apply -var-file="k8s.tfvars"` to do a Terraform apply.

You will see outputs representing the URL to access your ACS cluster in the Azure Portal, your private key PEM, and the FQDN of your cluster.  You will need these when using Terraform's Kubernetes Provider to provision Kubernetes pods and services in other configurations.

## Cleanup
Execute the following command to delete your Kubernetes cluster and associated resources from ACS.

1. Run `terraform destroy -var-file="k8s.tfvars"` to destroy the ACS cluster and other resources that were provisioned by Terraform. Done.
