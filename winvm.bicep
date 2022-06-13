@description('The name of the VM')
param virtualMachineName string = 'testVM'

@description('The admin user name of the VM')
param adminUsername string

@description('The admin password of the VM')
@secure()
param adminPassword string

@description('The Storage type of the data Disks')
@allowed([
  'StandardSSD_LRS'
  'Standard_LRS'
  'Premium_LRS'
])
param diskType string = 'StandardSSD_LRS'

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
param windowsOSVersion string = '2019-Datacenter'

@description('Virtual Network Name.')
param virtualNetworkName string = 'vnet_services_eastus'

@description('Vnet Subnet Name.')
param subnetName string = 'services_eastus'

@description('Vnet Resource Group Name.')
param vnetResourceGroupName string = 'rg_VSTest_Vnet'

@description('Location for all resources.')
param location string = resourceGroup().location

var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var OSDiskName = '${toLower(virtualMachineName)}OSDisk'
var publicIPAddressType = 'Dynamic'
var subnetRef = resourceId(vnetResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var networkInterfaceName_var = toLower(virtualMachineName)
var publicIpAddressName_var = '${toLower(virtualMachineName)}-ip'

resource publicIpAddressName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  name: publicIpAddressName_var
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: publicIPAddressType
  }
}

resource networkInterfaceName 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: networkInterfaceName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpAddressName.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
}

resource virtualMachineName_resource 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: virtualMachineName
  location: location
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
        osType: 'Windows'
        name: OSDiskName
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: diskType
        }
        diskSizeGB: 128
      }
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: windowsOSVersion
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName.id
        }
      ]
    }
  }
}