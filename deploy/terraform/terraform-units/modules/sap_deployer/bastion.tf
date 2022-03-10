// Create/Import bastion subnet
resource "azurerm_subnet" "bastion" {
  count                = var.bastion_deployment && !local.bastion_subnet_exists ? 1 : 0
  name                 = local.bastion_subnet_name
  resource_group_name  = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet_mgmt[0].resource_group_name : azurerm_virtual_network.vnet_mgmt[0].resource_group_name
  virtual_network_name = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet_mgmt[0].name : azurerm_virtual_network.vnet_mgmt[0].name
  address_prefixes     = [local.bastion_subnet_prefix]
}

data "azurerm_subnet" "bastion" {
  count                = var.bastion_deployment && local.bastion_subnet_exists ? 1 : 0
  name                 = split("/", local.bastion_subnet_arm_id)[10]
  resource_group_name  = split("/", local.bastion_subnet_arm_id)[4]
  virtual_network_name = split("/", local.bastion_subnet_arm_id)[8]
}

resource "azurerm_public_ip" "bastion" {
  count               = var.bastion_deployment ? 1 : 0
  name                = format("%s%s%s%s", local.prefix, var.naming.separator, "bastion", local.resource_suffixes.pip)
  resource_group_name  = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet_mgmt[0].resource_group_name : azurerm_virtual_network.vnet_mgmt[0].resource_group_name
  virtual_network_name = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet_mgmt[0].name : azurerm_virtual_network.vnet_mgmt[0].name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                = format("%s%s%s", local.prefix, var.naming.separator, "bastion-host")
  resource_group_name  = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet_mgmt[0].resource_group_name : azurerm_virtual_network.vnet_mgmt[0].resource_group_name
  virtual_network_name = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet_mgmt[0].name : azurerm_virtual_network.vnet_mgmt[0].name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.bastion_deployment && !local.bastion_subnet_exists ? azurerm_subnet.bastion[0].id : data.azurerm_subnet.bastion[0].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }
}
