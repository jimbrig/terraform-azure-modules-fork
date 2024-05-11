locals {
  identities = toset([
    "runner",
    "docrunner",
    "control-plane",
  ])
  repo_pool_names = tomap({
    "https://github.com/Azure/terraform" : "terraform-azurerm-doc"
    "https://github.com/Azure/terraform-azurerm-hubnetworking" : "terraform-azure-hubnetworking"
    "https://github.com/Azure/terraform-azure-container-apps" : "terraform-azurerm-container-apps"
    "https://github.com/Azure/terraform-azurerm-avm-res-storage-storageaccounts": "terraform-azure-storage-account"
  })
  repo_pool_max_runners = tomap({
    "https://github.com/Azure/terraform-azurerm-avm-ptn-virtualwan": 14
    "https://github.com/Azure/terraform-azurerm-avm-res-compute-disk": 5
  })
  bypass_set = toset([
    "https://github.com/Azure/terraform-azurerm-avm-res-authorization-roleassignment",   # needs access at higher scopes than subscription
    "https://github.com/Azure/terraform-azurerm-avm-ptn-alz",
    "https://github.com/Azure/terraform-azurerm-avm-res-storage-storageaccounts", # Would be cancelled by 1es, need further investigation
  ])
  repo_region = tomap({
    "https://github.com/Azure/terraform-azurerm-avm-ptn-virtualnetworkpeering": "westeurope",
    "https://github.com/lonegunmanb/avm-gh-app": "eastus2",
    "https://github.com/Azure/terraform-azurerm-avm-ptn-function-app-storage-private-endpoints": "eastus2",
    "https://github.com/Azure/terraform-azurerm-avm-res-compute-disk": "eastus2",
    "https://github.com/Azure/terraform-azurerm-avm-res-cache-redis": "eastus2",
    "https://github.com/Azure/terraform-azurerm-avm-res-insights-component": "eastus2",
    "https://github.com/Azure/terraform-azurerm-avm-res-search-searchservice": "eastus2",
    "https://github.com/Azure/terraform-azurerm-avm-res-logic-workflow": "eastus2",
    "https://github.com/Azure/terraform-azurerm-avm-ptn-policyassignment": "eastus2",
    "https://github.com/Azure/terraform-azurerm-avm-res-network-applicationsecuritygroup": "eastus2",
    "https://github.com/Azure/terraform-azurerm-avm-res-batch-batchaccount": "eastus2",
  })
  avm_res_mod_csv = file("${path.module}/Azure-Verified-Modules/docs/static/module-indexes/TerraformResourceModules.csv")
  avm_pattern_mod_csv = file("${path.module}/Azure-Verified-Modules/docs/static/module-indexes/TerraformPatternModules.csv")
  avm_res_mod_repos = [for i in csvdecode(local.avm_res_mod_csv) : i.RepoURL]
  avm_pattern_mod_repos = [for i in csvdecode(local.avm_pattern_mod_csv) : i.RepoURL]
  repos = [for r in concat([
    "https://github.com/Azure/terraform-azurerm-aks",
    "https://github.com/Azure/terraform-azurerm-compute",
    "https://github.com/Azure/terraform-azurerm-loadbalancer",
    "https://github.com/Azure/terraform-azurerm-network",
    "https://github.com/Azure/terraform-azurerm-network-security-group",
    "https://github.com/Azure/terraform-azurerm-postgresql",
    "https://github.com/Azure/terraform-azurerm-subnets",
    "https://github.com/Azure/terraform-azurerm-vnet",
    "https://github.com/Azure/terraform-azurerm-virtual-machine",
    "https://github.com/Azure/terraform",
    "https://github.com/Azure/terraform-azurerm-hubnetworking",
    "https://github.com/Azure/terraform-azurerm-openai",
    "https://github.com/Azure/terraform-azure-mdc-defender-plans-azure",
    "https://github.com/Azure/terraform-azurerm-database",
    "https://github.com/Azure/terraform-azure-container-apps",
    "https://github.com/Azure/terraform-azurerm-avm-res-storage-storageaccounts",
    "https://github.com/Azure/terraform-azurerm-avm-res-keyvault-vault",
    "https://github.com/WodansSon/terraform-azurerm-cdn-frontdoor",
    "https://github.com/Azure/avm-gh-app",
    "https://github.com/Azure/oneesrunnerscleaner",
  ], local.valid_avm_repos) : r if !contains(local.bypass_set, r)]
  repo_names = {
    for r in distinct(local.repos) : r => length(reverse(split("/", r))[0]) >= 45 ? sha1(reverse(split("/", r))[0]) : reverse(split("/", r))[0]
  }
  repos_fw = [
#    "https://github.com/lonegunmanb/terraform-azurerm-aks",
  ]
  # repos that use GitOps to manage testing infrastructures, not for verified modules
  repos_with_backend = [
    "https://github.com/lonegunmanb/TerraformModuleTelemetryService"
  ]
  runner_network_whitelist = sort(distinct([
    # OneES
    "*.dev.cloudtest.microsoft.com",
    "*.ppe.cloudtest.microsoft.com",
    "*.prod.cloudtest.microsoft.com",
    "ctdevbuilds.azureedge.net",
    "ctppebuilds.azureedge.net",
    "ctprodbuilds.azureedge.net",
    "vstsagentpackage.azureedge.net",
    "cloudtestdev.queue.core.windows.net",
    "cloudtestppe.queue.core.windows.net",
    "cloudtestintch1.queue.core.windows.net",
    "cloudtestprod.queue.core.windows.net",
    "cloudtestprodstampbn2.queue.core.windows.net",
    "cloudtestprodch1.queue.core.windows.net",
    "cloudtestprodco3.queue.core.windows.net",
    "cloudtestprodsn2.queue.core.windows.net",
    "stage.diagnostics.monitoring.core.windows.net",
    "production.diagnostics.monitoring.core.windows.net",
    "gcs.prod.monitoring.core.windows.net",
    "server.pipe.aria.microsoft.com",
    "azure.archive.ubuntu.com",
    "www.microsoft.com",

    "packages.microsoft.com",
    "ppa.launchpad.net",
    "dl.fedoraproject.org",
    "registry-1.docker.io",
    "auth.docker.io",
    "download.docker.com",
    "packagecloud.io",
    // 2.2 Needed by Azure DevOps agent: https://learn.microsoft.com/en-us/azure/devops/organizations/security/allow-list-ip-url?view=azure-devops&tabs=IP-V4
    "dev.azure.com",
    "*.services.visualstudio.com",
    "*.vsblob.visualstudio.com",
    "*.vssps.visualstudio.com",
    "*.visualstudio.com",
    # Github services
    "github.com",
    "api.github.com",
    "*.actions.githubusercontent.com",
    "raw.githubusercontent.com",
    "codeload.github.com",
    "actions-results-receiver-production.githubapp.com",
    "objects.githubusercontent.com",
    "objects-origin.githubusercontent.com",
    "github-releases.githubusercontent.com",
    "github-registry-files.githubusercontent.com",
    "*.blob.core.windows.net",
    "*.pkg.github.com",
    "ghcr.io",
    # Container registry
    "mcr.microsoft.com",
    "*.mcr.microsoft.com",
    "registry.hub.docker.com",
    "production.cloudflare.docker.com",
    "registry-1.docker.io",
    "auth.docker.io",
    # Golang
    "*.golang.org",
    "cloud.google.com",
    "go.opencensus.io",
    "golang.org",
    "gopkg.in",
    "k8s.io",
    "*.k8s.io",
    "storage.googleapis.com",
    # Terraform
    "registry.terraform.io",
    "releases.hashicorp.com",
    # Provision script
    "tfmod1esscript.blob.core.windows.net",
    # Azure service
    "graph.microsoft.com",
    "management.core.windows.net",
    "management.azure.com",
    "login.microsoftonline.com",
    "*.aadcdn.msftauth.net",
    "*.aadcdn.msftauthimages.net",
    "*.aadcdn.msauthimages.net",
    "*.logincdn.msftauth.net",
    "login.live.com",
    "*.msauth.net",
    "*.aadcdn.microsoftonline-p.com",
    "*.microsoftonline-p.com",
    "*.portal.azure.com",
    "*.hosting.portal.azure.net",
    "*.reactblade.portal.azure.net",
    "management.azure.com",
    "*.ext.azure.com",
    "*.graph.windows.net",
    "*.graph.microsoft.com",
    "*.account.microsoft.com",
    "*.bmx.azure.com",
    "*.subscriptionrp.trafficmanager.net",
    "*.signup.azure.com",
    "*.asazure.windows.net",
    "*.azconfig.io",
    "*.aad.azure.com",
    "*.aadconnecthealth.azure.com",
    "ad.azure.com",
    "adf.azure.com",
    "api.aadrm.com",
    "api.loganalytics.io",
    "api.azrbac.mspim.azure.com",
    "*.applicationinsights.azure.com",
    "appservice.azure.com",
    "*.arc.azure.net",
    "asazure.windows.net",
    "bastion.azure.com",
    "batch.azure.com",
    "catalogapi.azure.com",
    "catalogartifact.azureedge.net",
    "changeanalysis.azure.com",
    "cognitiveservices.azure.com",
    "config.office.com",
    "cosmos.azure.com",
    "*.database.windows.net",
    "datalake.azure.net",
    "dev.azure.com",
    "dev.azuresynapse.net",
    "digitaltwins.azure.net",
    "learn.microsoft.com",
    "elm.iga.azure.com",
    "venthubs.azure.net",
    "functions.azure.com",
    "gallery.azure.com",
    "go.microsoft.com",
    "help.kusto.windows.net",
    "identitygovernance.azure.com",
    "iga.azure.com",
    "informationprotection.azure.com",
    "kusto.windows.net",
    "learn.microsoft.com",
    "logic.azure.com",
    "marketplacedataprovider.azure.com",
    "marketplaceemail.azure.com",
    "media.azure.net",
    "monitor.azure.com",
    "mspim.azure.com",
    "network.azure.com",
    "purview.azure.com",
    "quantum.azure.com",
    "rest.media.azure.net",
    "search.azure.com",
    "servicebus.azure.net",
    "servicebus.windows.net",
    "shell.azure.com",
    "sphere.azure.net",
    "azure.status.microsoft",
    "storage.azure.com",
    "storage.azure.net",
    "*.storage.azure.com",
    "*.storage.azure.net",
    "vault.azure.net",
    "*.vault.azure.net",
    # Service for examples
    "api.bigdatacloud.net",
    "ipv4.seeip.org",
    "ifconfig.me",
    "api.ipify.org",
    # For debugger
#    "*.docker.com",
#    "aka.ms",
  ]))
}