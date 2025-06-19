# k8s-iac-framework
[![maintained by Osuite.io](https://img.shields.io/badge/maintained%20by-osuite.io-%235849a6.svg)](https://osuite.io/)
![License](https://img.shields.io/github/license/malayh/k8s-iac-framework.svg)
![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?logo=kubernetes&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?e&logo=amazon-aws&logoColor=white)


`k8s-iac-framework` is a simple framework to setup Kubernetes clusters and manage applications running on them. This is ideal when you need to operate multiple k8s clusters with many apps running on each cluster. The purpose of this is to standardize operations, configuration and lifecycle management of clusters and the apps running on them.

Following is what it does:
* Creation of k8s clusters using opentofu and terragrunt
* Automatically manages configurations for different environments using `safehelm`
* Automatically uses encrypted secrets. 
* Exposes a commands for standard operations 
* Creates a standard structure for your infra code repository.

# Usage
To setup a fresh repository with the framework do the following:

1. Create a repository for your infra code. eg. `my-infra-repo`
2. Inside `my-infra-repo`, run 
```
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/malayh/k8s-iac-framework/main/scripts/setup.sh | bash
```
3. Configure your tools
   * Setup your AWS credentials
   * Create terraform state bucket. Run `./scripts/setup_statebucket.sh bucket-name region`
   * Create KMS key and add your user to the key.
4. Edit configurations in `.env` file
5. Create environment to your need.
   * See `environments/stag/terragrunt.hcl` and `environments/common/terragrunt.hcl` for examples.
   * Run `just all` to create cluster and other resources. 
6. Configure kubectl to point to your cluser
   * Run `aws eks --region <region> update-kubeconfig --name <cluster-name>`
   * Verify the cluster is configured by running `kubectl get nodes`
7. Install system components
   * Update `charts/system/map.json` file to use your cluster
   * `cd charts/system && just setns && just install`
8. Install operators (optional)
   * Update `charts/operators/map.json` file to use your cluster
   * `cd charts/operators && just setns && just install`
9. Create charts for your backend: Follow instructions here: [How to run your apps](#how-to-run-your-apps)

Note: The terraform code included works with AWS EKS clusters. We will be adding other clouds here soon. Till then you can add your own terraform modules to create clusters on other cloud providers. 

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
   * **Please note that**:
      * Unlike helm, `safehelm` only works when you run it from the root of the chart directory. Which is why we are using standard justfiles to manage the command associated with charts.
      * Unlike other helm charts you don't need to pass `-f values.yaml` file to `safehelm`. It will automatically pick the value file from the `map.json` file.

## `Justfiles`
The framework uses `just` to various comamnds to manage lifecycles of the cluster and apps. 
* A `Justfile` is expected in root of every chart. That follows the structure of the `nocodb-example` chart
* A `Justfile` is expected in the root of the `terraform/environment`.

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
The `charts/system` chart is sets up essential system component like storage, ingress, cert-manager etc. It is expeted to be installed before any app chart. `cd` into the `charts/system` directory and run `just install` to install the system components. Extend this chart to add more system components as needed.

## `operators` chart
The `charts/operators` chart is sets up operators for your cluster. It is expeted to be installed before any app that uses operators. The goal of this chart to centralize management of all the operators that a cluster needs. `cd` into the `charts/operators` directory and run `just install` to install the operators.

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
└── templates/           # Helm templates for the app
```
`maps.json`, `Justfile`, `valuefiles` dir, `.sops.yaml` are non-standard things in this chart.
* `maps.json` - This file maps a k8s cluster and namespace to a value file. It is used by `safehelm` to bind the value file to the cluster and namespace. See the `safehelm` section for more details.
* `Justfile` - This file contains commands to use the chart. This file inherits from `charts/Justfile`. See `charts/Justfile` to see the available commands.
* `.sops.yaml` - This file is used to manage secrets using `sops`. Make sure `encrypted_regex` covers all the fields you want encrypted. See `charts/nocodb-example/.sops.yaml` for an example.
* `valuefiles/` - This directory contains environment specific values files. The `maps.json` file maps the k8s cluster and namespace to a value file in this directory.

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



