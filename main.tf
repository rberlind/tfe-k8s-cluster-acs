terraform {
  required_version = ">= 0.10.1"
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
}

provider "vault" {}

data "vault_generic_secret" "azure_credentials" {
  path = "secret/azure/credentials"
}

resource "vault_auth_backend" "k8s" {
  type = "kubernetes"
  path = "acs-${var.environment}"
  description = "Vault Auth backend for Kubernetes"
}

provider "azurerm" {
  subscription_id = "${data.vault_generic_secret.azure_credentials.data["subscription_id"]}"
  tenant_id       = "${data.vault_generic_secret.azure_credentials.data["tenant_id"]}"
  client_id       = "${data.vault_generic_secret.azure_credentials.data["client_id"]}"
  client_secret   = "${data.vault_generic_secret.azure_credentials.data["client_secret"]}"
}

# Azure Resource Group
resource "azurerm_resource_group" "k8sexample" {
  name     = "${var.resource_group_name}"
  location = "${var.azure_location}"
}

# Azure Container Service with Kubernetes orchestrator
resource "azurerm_container_service" "k8sexample" {
  name                   = "${var.cluster_name}"
  location               = "${azurerm_resource_group.k8sexample.location}"
  resource_group_name    = "${azurerm_resource_group.k8sexample.name}"
  orchestration_platform = "Kubernetes"

  master_profile {
    count      =  "${var.master_vm_count}"
    dns_prefix = "${var.dns_master_prefix}"
  }

  linux_profile {
    admin_username = "${var.admin_user}"
    ssh_key {
      key_data = "${chomp(tls_private_key.ssh_key.public_key_openssh)}"
    }
  }

  agent_pool_profile {
    name       = "${var.agent_pool_name}"
    count      =  "${var.worker_vm_count}"
    dns_prefix = "${var.dns_agent_pool_prefix}"
    vm_size    = "${var.vm_size}"
  }

  service_principal {
    client_id     = "${data.vault_generic_secret.azure_credentials.data["client_id"]}"
    client_secret = "${data.vault_generic_secret.azure_credentials.data["client_secret"]}"
  }

  diagnostics_profile {
    enabled = "${var.diagnostics_enabled}"
  }

  tags {
    Environment = "${var.environment}"
  }
}

resource "null_resource" "get_config" {
  provisioner "local-exec" {
    command = "echo '${chomp(tls_private_key.ssh_key.private_key_pem)}' > private_key.pem"
  }
  provisioner "local-exec" {
    command = "chmod 600 private_key.pem"
  }
  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -i private_key.pem azureuser@${lookup(azurerm_container_service.k8sexample.master_profile[0], "fqdn")}:~/.kube/config config"
  }
  provisioner "local-exec" {
    command = "cat config"
  }
  depends_on = ["azurerm_container_service.k8sexample"]
}

/*resource "null_resource" "auth_config" {
  provisioner "local-exec" {
    command = "curl --header \"X-Vault-Token: $VAULT_TOKEN\" --header \"Content-Type: application/json\" --request POST --data '{ \"kubernetes_host\": \"https://${lookup(azurerm_container_service.k8sexample.master_profile[0], "fqdn")}:443\", \"token_reviewer_jwt\": \"reviewer_service_account_jwt\", \"kubernetes_ca_cert\": \"${chomp(replace(base64decode(google_container_cluster.k8sexample.master_auth.0.cluster_ca_certificate), "\n", "\\n"))}\" }' $VAULT_ADDR/v1/auth/${vault_auth_backend.k8s.path}config"
  }
  depends_on = ["null_resource.get_config"]
}*/
