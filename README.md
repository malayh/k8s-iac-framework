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

# Usage
This repository provides a framework for setting up Kubernetes clusters and managing applications using Helm charts, Terraform. Here is how to use it.

1. Create a repository for your infra code. eg. `my-infra-repo`
2. Inside `my-infra-repo`, run 
```
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/malayh/k8s-iac-framework/main/scripts/setup.sh | bash
```

# Tools and concepts
The project uses `helm`, `just`, `sops`, `tofu`, `terragrunt`, `kubectl` and `aws`. 

## `safehelm`
It is thin wrapper around helm.

   * It binds a value file to a k8s cluster and namespace. So that if you have multiple clusters configured for `kubectl`, you don't accidentally apply changes to the wrong cluster.
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

## How to run your apps
You define your app's chart in `charts/<app-name>` directory. The structure of the chart is the same as any helm chart with a few additions. Here is the intended structure of a chart. You cd into the chart directory and run `just install` to install the app.

```
├── charts/my-app-backend/       
├── Justfile             # Justfile for the app to manage app lifecycles
├── maps.json            # Maps k8s cluster and namespace
├── .sops.yaml           # Sops config file to manage secrets
├── Chart.yaml           # Helm chart metadata file
├── values.yaml          # Default values file for the app
├── valuefiles/          # Environment specific values files
├── templates/           # Helm templates for the app
```
`maps.json`, `Justfile`, `valuefiles` dir, `.sops.yaml` are non-standard things in this chart.
* `maps.json` - This file maps a k8s cluster and namespace to a value file. It is used by `safehelm` to bind the value file to the cluster and namespace. See the `safehelm` section for more details.
* `Justfile` - This file is used to manage the app lifecycle. It contains commands. This file inherits from `charts/Justfile`. See `charts/Justfile` to see the available commands.
* `.sops.yaml` - This file is used to manage secrets using `sops`. Make sure `encrypted_regex` covers all the fields you want encrypted. See `charts/nocodb-example/.sops.yaml` for an example.
* `valuefiles` - This directory contains environment specific values files. The `maps.json` file maps the k8s cluster and namespace to a value file in this directory.

### How to create a new environment specific values file.
You must never put secrets in the default `values.yaml` file. Because this file remains unencrypted. Think of this file as the default values for the app regardless of the environment. 

Here are the steps to create a new environment specific values file:
* Create a new file `valuefiles/values.<env>.yaml` file
* Put your secrets in it and `just sops-lock valuefiles/values.<env>.yaml` to encrypt it. 
* Update you `maps.json` file to map the k8s cluster and namespace to the new value file.
* Run `just install` to install the app with the new values file.
* Commit the changes to git
* Run `sops edit valuefiles/values.<env>.yaml` to edit the file in an editor of your choice. This will decrypt the file, open it in the editor and re-encrypt it when you save and close the editor.

See the `charts/nocodb-example` for example.



