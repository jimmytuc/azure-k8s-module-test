# Kubernetes module

Terraform module to deploy a Kubernetes cluster on Azure by using the managed Kubernetes solution AKS. For security reasons it will only deploy a rbac enabled clusters and requires an Azure AD application for authenticating users. This account can be created with the module [avinor/kubernetes-azuread-integration/azurerm](https://github.com/avinor/terraform-azurerm-kubernetes-azuread-integration). Service principal required can be created with [avinor/service-principal/azurerm](https://github.com/avinor/terraform-azurerm-service-principal) module. It is not required to grant the service principal any roles, this module will make sure to grant required roles. That does however mean that the deployment has to run with Owner priviledges.

From version 1.5.0 of module it will assign the first node pool defined as the default one, this cannot be changed later. If changing any variable that requires node pool to be recreated it will recreate entire cluster, that includes name, vm size etc. Make sure this node pool is not changed after first deployment. Other node pools can change later.

## Available version

To get a list of available Kubernetes version in a region run the following command. Replace `southeast` with region of choice.

```bash
az aks get-versions --location westeurope --query "orchestrators[].orchestratorVersion"
```

## Roles

This module will assign the required roles for cluster. These are based on the [Microsoft documentation](https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal). The variables `container_registries` and `storage_contributor` can be used to grant it access to container registries and storage accounts.

If cluster needs to manage some Managed Identities that can be done by using the input variable `managed_identities`. The AKS service principal will be granted `Managed Identity Operator` role to those identities.

## Service accounts

Using the `service_accounts` variable it is possible to create some default service accounts. For instance to create a service account with `cluster_admin` role that can be used in CI / CI pipelines. It is not recommended to use the admin credentials as they cannot be revoked later.
