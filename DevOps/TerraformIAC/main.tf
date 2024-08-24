# Resource Group
resource "azurerm_resource_group" "ExpatSwap_rg" {
  name     = "ExpatSwap-webapp-rg"
  location = var.location
}

# Virtual Network (VNet)
resource "azurerm_virtual_network" "ExpatSwap_vnet" {
  name                = "ExpatSwap-webapp-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.ExpatSwap_rg.location
  resource_group_name = azurerm_resource_group.ExpatSwap_rg.name
}

# Public Subnet
resource "azurerm_subnet" "ExpatSwap_public_subnet" {
  name                 = "ExpatSwap-public-subnet"
  resource_group_name  = azurerm_resource_group.ExpatSwap_rg.name
  virtual_network_name = azurerm_virtual_network.ExpatSwap_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP Address
resource "azurerm_public_ip" "ExpatSwap_public_ip" {
  name                = "ExpatSwap-webapp-public-ip"
  location            = azurerm_resource_group.ExpatSwap_rg.location
  resource_group_name = azurerm_resource_group.ExpatSwap_rg.name
  allocation_method   = "Dynamic"
}

# Network Security Group (NSG)
resource "azurerm_network_security_group" "ExpatSwap_nsg" {
  name                = "ExpatSwap-webapp-nsg"
  location            = azurerm_resource_group.ExpatSwap_rg.location
  resource_group_name = azurerm_resource_group.ExpatSwap_rg.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Interface (NIC)
resource "azurerm_network_interface" "ExpatSwap_nic" {
  name                = "ExpatSwap-webapp-nic"
  location            = azurerm_resource_group.ExpatSwap_rg.location
  resource_group_name = azurerm_resource_group.ExpatSwap_rg.name

  ip_configuration {
    name                          = "ExpatSwap-webapp-ip-config"
    subnet_id                     = azurerm_subnet.ExpatSwap_public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ExpatSwap_public_ip.id
  }
}

# Virtual Machine (VM)
resource "azurerm_linux_virtual_machine" "ExpatSwap_vm" {
  name                = "ExpatSwap-webapp-vm"
  resource_group_name = azurerm_resource_group.ExpatSwap_rg.name
  location            = azurerm_resource_group.ExpatSwap_rg.location
  size                = var.vm_size

  admin_username = "azureuser"
  admin_password = "P@ssw0rd1234!"  # Replace this with a secure method for production environments

  network_interface_ids = [azurerm_network_interface.ExpatSwap_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# Install and Configure Nginx and Node.js
resource "azurerm_virtual_machine_extension" "ExpatSwap_install_nginx_node" {
  name                 = "ExpatSwap-install-nginx-node"
  virtual_machine_id   = azurerm_linux_virtual_machine.ExpatSwap_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "apt-get update && apt-get install -y nginx nodejs npm && git clone https://github.com/username/repo.git /var/www && cd /var/www && npm install && npm run build && npm start && systemctl start nginx"
    }
  SETTINGS
}
