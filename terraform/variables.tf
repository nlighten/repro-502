variable "vm_sku" {
  type        = string
  description = "sku for aks cluster vm's"
  default     = "Standard_D4s_v5"
}

variable "vm_disk_type" {
  type        = string
  description = "disk type for aks cluster vm's (Managed/Ephemeral)"
  default     = "Managed"
}

variable "aks_network_plugin" {
  type = string
  description = "AKS network plugin (kubenet/azure)"
  default = "azure"
}