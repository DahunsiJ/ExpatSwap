variable "location" {
  description = "The Azure region where resources will be created"
  default     = "East US"
}

variable "vm_size" {
  description = "The size of the Virtual Machine"
  default     = "Standard_B1s"
}
