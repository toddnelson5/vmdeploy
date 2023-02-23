@description('The name of the VM')
param virtualMachineName string = 'testVM'

@description('The admin user name of the VM')
param adminUsername string

@description('The admin password of the VM')
@secure()
param adminPassword string

@description('The Storage type of the data Disks')
@allowed([
  'Premium_LRS'
  'StandardSSD_LRS'
  'Standard_LRS'
])
param diskType string = 'Premium_LRS'

@description('The virtual machine size. Enter a Premium capable VM size if DiskType is entered as Premium_LRS')
param virtualMachineSize string = 'Standard_B2MS'

@description('The Windows version for the VM.')
@allowed([
  '2012-Datacenter'
  '2012-R2-Datacenter'
  '2016-Datacenter'
  '2019-Datacenter'
  '2022-Datacenter'
])
param windowsOSVersion string = '2022-Datacenter'

@description('Virtual Network Name.')
param virtualNetworkName string = 'vnet_services_eastus'

@description('Vnet Subnet Name.')
param subnetName string = 'services_eastus'

@description('Vnet Resource Group Name.')
param vnetResourceGroupName string = 'rg_vnet_service'

@description('Location for all resources.')
param location string = resourceGroup().location
param resourceTags object = {
  Environment: 'Services'
  Created_By: 'Dataprise'
}

var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var OSDiskName = '${toLower(virtualMachineName)}OSDisk'
var publicIPAddressType = 'Dynamic'
var subnetRef = resourceId(vnetResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var networkInterfaceName = toLower(virtualMachineName)
var publicIpAddressName = '${toLower(virtualMachineName)}-ip'
var storageAccountName = 'diags${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  tags: resourceTags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  tags: resourceTags
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  name: publicIpAddressName
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: publicIPAddressType
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: networkInterfaceName
  location: location
  tags: resourceTags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpAddress.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: virtualMachineName
  location: location
  tags: resourceTags
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      osDisk: {
        name: OSDiskName
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: diskType
        }
      }
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: windowsOSVersion
        version: 'latest'
      }
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccount.properties.primaryEndpoints.blob
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
  }
}