* Tools installation
* Terraform infra
* Sytsem charts
* App example with SOP
* Cohesive script to tie it all together

# Install setup
* Install tools
* Install tofu stuff
* Connect to k8s cluster
* Install system chart
* Install operators
* Map DNS records to ingress endpoint
* Install apps


# How to setup sops
* Create KMS key
* Add user to the key 


# Outline
* Why this repo?
   * Framework for setting up k8s clusters with tools to operate the clusters 
* What is in this repo?
   * Terraform code to setup k8s clusters. It uses terragrunt to manage mutiple environments
   * `safehelm`, customer wrapper around helm to manage secrets and multiple environments seemslessly
   * Chart to setup system components: storage, ingress and certificate management
   * Chart to setup operators
   * Justfiles to standardize lifecycle management of the clusters and apps

* How to use this repo?
   * Install tools 
   * Setup aws credentials, KMS keys, tf state bucket
   * Setup k8s cluster
   * Install system charts
   * Install operators

* How to add an app?
   * Create a new chart
   * Create a new Justfile as shown in the example
   * Create a `.sops.yaml` file to manage secrets
   * Create `maps.yaml` file to manage different k8s clusters
   * Create the default `values.yaml` file. 
   * Create the `valuefiles/values.<env>.yaml` file and map it to the `cluster//namespace` in the `maps.yaml` file
   * `just install`


* Concepts
    * `safehelm` - a wrapper around helm to manage secrets and multiple environments
       * How to use this
    * `Justfiles`
    * Helm charts structure
    * System chart
    * Operator chart



# Tools and concepts
The project uses `helm`, `just`, `sops`, `tofu`, `terragrunt`, `kubectl` and `aws`. 

## `safehelm`
It is thin wrapper around helm. It 

   * It binds a value file to a k8s cluster and namespace. It is so that if you have multiple clusters configured for `kubectl`, you don't accidentally apply changes to the wrong cluster.
   * `safehelm` expects a `map.json` file in the root for of the chart directory that maps a cluster and specific namespace to a value file. The following is an example of the `map.json` file. It binds the `values.prod.yaml` file to the `ingress-nginx` namespace in the `prod-cluster` cluster and binds a different file for stage cluster. 
   ```json
   {
      "arn:aws:eks:ap-south-1:12314412334:cluster/prod-cluster//ingress-nginx" : "valuefiles/values.prod.yaml",
      "arn:aws:eks:ap-south-1:12314412334:cluster/stage-cluster//ingress-nginx" : "valuefiles/values.stage.yaml"
   }
   ```
   * If `kubectl` is not configured to point to the cluster specified in the `map.json` file, `safehelm` will throw an error. To fix this you need to run:
   ```bash
   kubectl config use-context arn:aws:eks:ap-south-1:12314412334:cluster/prod-cluster
   kubectl config set-context --current --namespace ingress-nginx
   ```

   * If `values.ingress.yaml` is a `sops` encrypted file, `safehelm` will decrypt it before upgrading/installing the chart. 

## `Justfiles`
The framework uses `just` to various comamnds to manage lifecycles of the cluster and apps. 
* A `Justfile` is expected in root of every chart. That follows the structure of the `nocodb-example` chart

## Directory structure
There is two core part of the repo. `terraform` and `charts`. 
The `terraform` directory contains the code to setup k8s clusters in multiple environments using `terragrunt`. The `charts` directory contains the helm charts to setup system components, operators and apps.

```
my-infra-repo/                   # Root of your infra repo
├── .env                         # Environment variables file to set up your infra
├── charts/
├── ├── Justfile                 # Common Justfile for all the charts, to manage app lifecycles
├── ├── system/                  # System chart to setup system components like storage, ingress, cert-manager, etc.
├── ├── operators/               # Operators chart to setup operators for your cluster. 
├── ├── my-app-backend/          # Your app's chart
├── ├── ├── Justfile             # Justfile for the app to manage app lifecycles
├── ├── ├── maps.json            # Maps k8s cluster and namespace
├── ├── ├── .sops.yaml           # Sops config file to manage secrets
├── ├── ├── Chart.yaml           # Helm chart metadata file
├── ├── ├── values.yaml          # Default values file for the app
├── ├── ├── valuefiles/          # Environment specific values files
├── ├── ├── templates/           # Helm templates for the app
├── terraform/
├── ├── modules/                 # Terraform modules for your infra
├── ├── ├── aws-eks/             # AWS EKS module
├── ├── ├── aws-vpc/             # AWS VPC module
├── ├── ├── aws-something/      
├── ├── environments/            # Your environments (dev, stage, prod, etc.)
├── ├── ├── terragrunt.hcl       # Root Terragrunt config file.
├── ├── ├── Jusfile              # Justfile to manage infra lifecycle
├── ├── ├── common/              # Common resources shared across environments
├── ├── ├── ├── terragrunt.hcl
├── ├── ├── stag/
├── ├── ├── ├── terragrunt.hcl   # Stage environment specific config 
├── ├── ├── prod/
└── └── └── └── terragrunt.hcl   # Prod environment specific config 
```
## `system` chart
The `charts/system` chart is sets up essential system component like storage, ingress, cert-manager etc. It is expeted to install before any app chart. `cd` into the `charts/system` directory and run `just install` to install the system components. Extend this chart to add more system components as needed.

## `operators` chart
The `charts/operators` chart is sets up operators for your cluster. It is expeted to install before any app that uses operators. The goal of this chart to centralize management of all the operators that a cluster needs. `cd` into the `charts/operators` directory and run `just install` to install the operators.

### How to add more operators
* Add a dependency to the `Chart.yaml` file. Put condition so that you can exclude it from installation in you don't need it in a specific environment.
* Add default configs in `values.yaml` file. 
* Define a `valuefiles/values.<env>.yaml` file to override the default values for a specific environment.
* `just install` to install the operators.







