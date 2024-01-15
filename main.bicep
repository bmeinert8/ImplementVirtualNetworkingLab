@description('The location where the resources are to be deployed.')
param location string = resourceGroup().location

@description('The address prefix of the virtual network.')
param virtualNetworkAddressPrefix string = '10.0.0.0/16'

@description('The address prefix of the first subnet in the virtual network.')
param firstSubnetAddressPrefix string = '10.0.0.0/24'

@description('The address prefix of the second subnet in the virtual network.')
param secondSubnetAddressPrefix string = '10.0.1.0/24'

@description('The name of the SKU of the public IP address to deploy.')
param publicIPAddressSkuName string = 'Standard'

@description('The Size of the virtual machine.')
param vmSize string = 'Standard_B1s'

@description('The storage type of the vm storage disk')
param virtualMachineManagedDiskStorageAccountType string = 'Premium_LRS'

@description('The admin username for the virtual machines.')
@secure()
param adminUsername string

@description('The admin password for the virtual machines.')
@secure()
param adminPassword string



var virtualNetworkName = 'Vnet1eus2'
var firstSubnetName = 'subnet0'
var secondSubnetName = 'subnet1'
var networkSecurityGroupName = 'nsg1eus2'
var rdpNetworkSecurityGroupRuleName = 'AllowRDPInBound'
var rdpNetworkSecurityGroupRuleProperties = {
  protocol: 'TCP'
  sourcePortRange: '*'
  destinationPortRange: '3389'
  sourceAddressPrefix: '*'
  destinationAddressPrefix: '*'
  access: 'Allow'
  priority: 300
  direction: 'Inbound'
}
var publicIPAddress1Name = 'Pip0eus2'
var publicIPAddress2Name = 'Pip1eus2'
var vm1NetworkInterfaceName = 'Nic0eus2'
var vm2NetworkInterfaceName = 'Nic1eus2'
var virtualMachine1Name = 'vm0eus2'
var virtualMachine2Name = 'vm1eus2'
var virtualMAchineImageReference =  {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2019-Datacenter'
  version: 'latest'
}
var osDisk1Name = 'vm1OSDisk'
var osDisk2Name = 'vm2OSDisk'
var dnsZoneName = 'vnetlab.org'
var vm1DNSRecordName = 'vm1'
var vm2DNSRecordName = 'vm2'
var privateDnsZoneName = 'vnetlab.org'
var virtualNetworkLinkName = 'vnet1-link'




resource VirtualNetwork 'Microsoft.Network/virtualNetworks@2023-06-01' ={
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
    subnets: [
      {
        name: firstSubnetName
        properties: {
          addressPrefix: firstSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: secondSubnetName
        properties: {
          addressPrefix: secondSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    enableDdosProtection: false
  }

  resource firstSubnet 'subnets' existing = {
    name: firstSubnetName
  }

  resource secondSubnet 'subnets' existing = {
    name: secondSubnetName
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-06-01' ={
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: rdpNetworkSecurityGroupRuleName
        properties: rdpNetworkSecurityGroupRuleProperties
      }
    ]
  }
  resource RDPNetworkSecurityGroupRule 'securityRules' existing = {
    name: rdpNetworkSecurityGroupRuleName
  }
}

resource vm1PublicIPAddress 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: publicIPAddress1Name
  location: location
  sku: {
    name: publicIPAddressSkuName
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource vm2PublicIPAddress 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: publicIPAddress2Name
  location: location
  sku: {
    name: publicIPAddressSkuName
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource vm1NetworkInterface 'Microsoft.Network/networkInterfaces@2023-06-01' = {
  name: vm1NetworkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: vm1PublicIPAddress.id
          }
          subnet: {
            id: VirtualNetwork::firstSubnet.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableIPForwarding: false
    disableTcpStateTracking: false
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
    nicType: 'Standard'
  }
}

resource vm2NetworkInterface 'Microsoft.Network/networkInterfaces@2023-06-01' = {
  name: vm2NetworkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: vm2PublicIPAddress.id
          }
          subnet: {
            id: VirtualNetwork::secondSubnet.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableIPForwarding: false
    disableTcpStateTracking: false
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
    nicType: 'Standard'
  }
}

resource virtualMachine1 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: virtualMachine1Name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: virtualMAchineImageReference
      osDisk: {
        osType: 'Windows'
        name: osDisk1Name
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: virtualMachineManagedDiskStorageAccountType
        }
      }
    }
    osProfile: {
      computerName: virtualMachine1Name
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
        }
        enableVMAgentPlatformUpdates: false
      }
      secrets: []
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vm1NetworkInterface.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
}

resource virtualMachine2 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: virtualMachine2Name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: virtualMAchineImageReference
      osDisk: {
        osType: 'Windows'
        name: osDisk2Name
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: virtualMachineManagedDiskStorageAccountType
        }
      }
    }
    osProfile: {
      computerName: virtualMachine2Name
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
        }
        enableVMAgentPlatformUpdates: false
      }
      secrets: []
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vm2NetworkInterface.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
}

resource dnsZone 'Microsoft.Network/dnszones@2018-05-01' = {
  name: dnsZoneName
  location: 'global'
  properties: {
    zoneType: 'Public'
  }
  resource vm1DNSRecord 'A' = {
    name: vm1DNSRecordName
    properties: {
      TTL: 3600
      ARecords: [
        {
          ipv4Address: vm1PublicIPAddress.id
        }
      ]
    }
  }
  resource vm2DNSRecord 'A' = {
    name: vm2DNSRecordName
    properties: {
      TTL: 3600
      ARecords: [
        {
          ipv4Address: vm2PublicIPAddress.id
        }
      ]
      targetResource: {}
    }
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZoneName
  location: 'global'
  
  resource privateDnsZones_contoso_org_name_vnet1_link 'virtualNetworkLinks' = {
    name: virtualNetworkLinkName
    location: 'global'
    properties: {
      registrationEnabled: true
      virtualNetwork: {
        id: VirtualNetwork.id
      }
    }
  }
}
