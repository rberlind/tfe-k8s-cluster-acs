output "k8s_id" {
  value = "${azurerm_container_service.k8sexample.id}"
}

output "private_key_pem" {
  value = "${chomp(tls_private_key.ssh_key.private_key_pem)}"
}

output "acs_master_fqdn" {
  value = "${lookup(azurerm_container_service.k8sexample.master_profile[0], "fqdn")}"
}
