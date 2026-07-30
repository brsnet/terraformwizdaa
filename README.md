# Terraform — wizdaa-lab Namespace

Provisions the `wizdaa-lab` Kubernetes namespace on a local Docker Desktop cluster.

## Prerequisites

| Tool | Minimum version |
|------|----------------|
| Terraform | >= 1.3.0 |
| kubectl | any |
| Docker Desktop (Kubernetes enabled) | any |

Confirm your context is set correctly before applying:

```bash
kubectl config current-context   # must return: docker-desktop
```

## Structure

```
terraform/
├── main.tf        # Provider config and namespace resource
├── variables.tf   # Input variables (context, namespace name)
├── outputs.tf     # Namespace name and UID outputs
└── README.md
```

## Usage

```bash
# 1. Initialize providers
terraform init

# 2. Preview changes
terraform plan

# 3. Apply
terraform apply

# 4. Verify
kubectl get namespace wizdaa-lab --show-labels
```

## Variables

| Name | Default | Description |
|------|---------|-------------|
| `kube_context` | `docker-desktop` | kubeconfig context to target |
| `namespace` | `wizdaa-lab` | Name of the namespace to create |

Override at apply time if needed:

```bash
terraform apply -var="namespace=my-other-lab"
```

## Outputs

| Name | Description |
|------|-------------|
| `namespace_name` | Name of the created namespace |
| `namespace_uid` | UID assigned by Kubernetes |

## Cleanup

```bash
terraform destroy
```
