# Terraform AWS EC2 Fundamentals

A beginner-friendly, hands-on project demonstrating how to provision and manage an AWS EC2 instance using Terraform.

This project covers Terraform fundamentals, AWS authentication, variables, SSM Parameter Store, EC2, state management, Git hygiene, and common DevOps interview questions.

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture and Workflow](#2-architecture-and-workflow)
3. [Prerequisites](#3-prerequisites)
4. [Project Structure](#4-project-structure)
5. [How the Terraform Files Work](#5-how-the-terraform-files-work)
6. [Step-by-Step Deployment](#6-step-by-step-deployment)
7. [Understanding Terraform State](#7-understanding-terraform-state)
8. [Updating and Destroying Infrastructure](#8-updating-and-destroying-infrastructure)
9. [Understanding .gitignore](#9-understanding-gitignore)
10. [Git and GitHub Workflow](#10-git-and-github-workflow)
11. [Terraform Command Reference](#11-terraform-command-reference)
12. [Troubleshooting](#12-troubleshooting)
13. [Interview Questions and Answers](#13-interview-questions-and-answers)
14. [Best Practices](#14-best-practices)

---

## 1. Project Overview

### What is Terraform?

Terraform is an Infrastructure as Code (IaC) tool. It allows us to define infrastructure using configuration files instead of creating every resource manually through a cloud console.

For example, instead of manually creating an EC2 instance in the AWS Console, we can define the desired instance in Terraform and run commands to provision it.

### Project objectives

- Understand Infrastructure as Code.
- Configure the Terraform AWS provider.
- Authenticate with AWS using a named CLI profile.
- Use variables and a `terraform.tfvars` file.
- Retrieve an Ubuntu AMI ID from AWS Systems Manager Parameter Store.
- Create and manage an EC2 instance.
- Understand data sources and managed resources.
- Learn how Terraform state works.
- Practise `plan`, `apply`, `state show`, and `destroy`.
- Understand `.gitignore`, Git, and GitHub basics.

### Infrastructure created

| Property | Value |
|---|---|
| Cloud provider | AWS |
| AWS region | `ap-south-1` (Mumbai) |
| Operating system | Ubuntu Server 24.04 |
| Instance type | `t3.micro` |
| AWS profile | `dev` |
| Terraform resource | `aws_instance.web_ec2` |

The instance uses the default VPC networking configuration selected by AWS when no custom networking is specified.

---

## 2. Architecture and Workflow

The project follows this workflow:

```text
Developer
   |
   v
Terraform Configuration
   |
   v
AWS Provider and Authentication
   |
   v
AWS Systems Manager Parameter Store
   |
   v
Ubuntu AMI ID
   |
   v
EC2 Instance
   |
   v
Terraform State
```

### How it works

1. We write Terraform configuration in `.tf` files.
2. Terraform uses the AWS provider to communicate with AWS.
3. The configured AWS profile supplies credentials.
4. A data source reads the current Ubuntu AMI ID from SSM Parameter Store.
5. The EC2 resource uses the AMI ID to create an instance.
6. Terraform records information about the data source and EC2 instance in state.
7. On future runs, Terraform compares the configuration, state, and observed infrastructure to determine the changes required.

**Important:** SSM supplies the AMI ID. Terraform does not create the Ubuntu AMI or the public SSM parameter.

---

## 3. Prerequisites

Before starting, install and configure the following:

- Terraform CLI
- AWS CLI
- Git
- An AWS account
- An AWS CLI profile with the required permissions

Check the installed tools:

```bash
terraform version
aws --version
git --version
```

**Why run these commands?**

They confirm that the required tools are installed and available in your terminal.

### Verify AWS authentication

```bash
aws sts get-caller-identity --profile dev
```

**Why?**

This checks which AWS identity your named profile is using. It helps avoid creating resources in the wrong account.

### Verify the AWS region

```bash
aws configure get region --profile dev
```

This checks the region configured in the AWS CLI profile. The Terraform provider also specifies the region used by this project.

---

## 4. Project Structure

```text
terraform_ec2/
├── versions.tf
├── providers.tf
├── variable.tf
├── terraform.tfvars
├── ec2.tf
├── outputs.tf
├── .gitignore
├── .terraform.lock.hcl
└── README.md
```

Terraform automatically loads `.tf` files from the current working directory. The filenames can be different, but their Terraform blocks must be valid.

| File | Responsibility |
|---|---|
| `versions.tf` | Specifies required Terraform and provider versions. |
| `providers.tf` | Configures the AWS provider, region, and profile. |
| `variable.tf` | Declares input variables. |
| `terraform.tfvars` | Supplies values for the declared variables. |
| `ec2.tf` | Defines the SSM data source and EC2 resource. |
| `outputs.tf` | Declares values to display after deployment. |
| `.gitignore` | Excludes selected local files from Git tracking. |
| `.terraform.lock.hcl` | Locks provider selections and checksums. |
| `README.md` | Documents the project. |

Terraform also creates local working files and state files during normal operation.

---

## 5. How the Terraform Files Work

### 5.1 `versions.tf` — Provider requirements

This file specifies which provider Terraform needs.

Example:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.67.0"
    }
  }
}
```

**Why is this needed?**

- `required_providers` declares the provider dependency.
- `source` identifies the AWS provider published by HashiCorp.
- `version` constrains the provider version Terraform can select.

The version constraint `~> 6.67.0` allows compatible patch releases in the `6.67.x` series.

### 5.2 `providers.tf` — AWS provider configuration

Example:

```hcl
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
```

**Why is this needed?**

The AWS provider lets Terraform communicate with AWS APIs.

- `region` specifies where Terraform will manage resources.
- `profile` selects the AWS CLI profile.
- `var.aws_region` and `var.aws_profile` reference input variables.

The provider configuration does not create an EC2 instance by itself.

### 5.3 `variable.tf` — Input variable declarations

Example:

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
```

**Why is this needed?**

Variables make configuration reusable. Instead of hardcoding `t3.micro` in the resource, we reference `var.instance_type`.

A variable declaration defines an input; it does not necessarily supply its final value. The value may come from a default, a `.tfvars` file, a command-line argument, or another supported input mechanism.

### 5.4 `terraform.tfvars` — Variable values

Example:

```hcl
aws_region  = "ap-south-1"
aws_profile = "dev"

ami_ssm_parameter_name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"

instance_type = "t3.micro"
environment   = "dev"

instance_name = "lounch-ec2-terrafrom"
managed_by    = "Terraform"
```

**Why is this needed?**

It separates environment-specific values from the resource definitions. Terraform automatically loads a file named `terraform.tfvars` from the working directory.

The values must match variables declared in the configuration. Variable names are case-sensitive.

### 5.5 `ec2.tf` — Data source and EC2 resource

```hcl
data "aws_ssm_parameter" "ubuntu" {
  name = var.ami_ssm_parameter_name
}

resource "aws_instance" "web_ec2" {
  ami           = data.aws_ssm_parameter.ubuntu.value
  instance_type = var.instance_type

  tags = {
    Name        = var.instance_name
    Environment = var.environment
    ManagedBy   = var.managed_by
  }
}
```

**Why is this needed?**

The data source reads the Ubuntu AMI ID from SSM Parameter Store.

The resource then uses that ID to create the EC2 instance.

The tags help identify the instance and its environment.

### 5.6 `outputs.tf` — Display useful results

Example:

```hcl
output "instance_id" {
  description = "ID of the managed EC2 instance"
  value       = aws_instance.web_ec2.id
}

output "instance_type" {
  description = "Type of the EC2 instance"
  value       = aws_instance.web_ec2.instance_type
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web_ec2.public_ip
}
```

**Why is this needed?**

Outputs display useful information after deployment. They are not required to create the instance.

After adding outputs, run:

```bash
terraform apply
terraform output
```

If no outputs are declared, Terraform can report that no outputs were found.

**Security note:** Public IP output is not a guarantee that the instance is reachable. Network routes, security groups, and other settings determine connectivity.

---

## 6. Step-by-Step Deployment

Run the commands from the project directory.

### Step 1: Navigate to the project

```bash
cd ~/learig_hub/terraform_learing/terraform_ec2
```

**Why?**

Terraform commands operate on the current working directory. Running them in the wrong directory could use a different configuration or state.

### Step 2: Initialize Terraform

```bash
terraform init
```

**Why?**

Terraform initializes the working directory, downloads required providers, and prepares the backend.

Run it when starting the project or after relevant provider or backend configuration changes.

### Step 3: Format the configuration

```bash
terraform fmt
```

**Why?**

It formats Terraform files consistently, making the configuration easier to read and review.

### Step 4: Validate the configuration

```bash
terraform validate
```

**Why?**

It checks the configuration's syntax and internal consistency. It does not guarantee that AWS permissions are sufficient or that deployment will succeed.

### Step 5: Review the execution plan

```bash
terraform plan
```

**Why?**

Terraform calculates and displays the changes it proposes to make.

Review the output for unexpected additions, modifications, or deletions before proceeding.

### Step 6: Apply the configuration

```bash
terraform apply
```

**Why?**

Terraform displays a plan and asks for approval before executing it. After confirmation, it creates or updates the resources.

### Step 7: Inspect the state

```bash
terraform state list
```

Expected entries for this project may include:

```text
data.aws_ssm_parameter.ubuntu
aws_instance.web_ec2
```

**Why?**

This command lists objects recorded in the current Terraform state. It does not list every resource in your AWS account.

### Step 8: Inspect the EC2 resource

```bash
terraform state show aws_instance.web_ec2
```

**Why?**

It displays attributes recorded for that specific resource, such as the instance ID, instance type, tags, and IP addresses.

### Step 9: Inspect the complete state

```bash
terraform show
```

**Why?**

It displays the current state in a human-readable form. Unlike `terraform state show`, this command is not intended to select a single object by its resource address.

### Step 10: Display outputs

```bash
terraform output
```

**Why?**

It displays the outputs declared in `outputs.tf`. It may report that no outputs are found if none are defined.

### Step 11: Verify AWS directly

```bash
aws ec2 describe-instances \
  --region ap-south-1 \
  --profile dev
```

**Why?**

This queries AWS directly to inspect the instances visible to that profile in the specified region. It complements Terraform's state inspection.

---

## 7. Understanding Terraform State

### 7.1 What is Terraform state?

Terraform state records information Terraform uses to map configuration objects to real infrastructure.

For a local backend, the main state file is usually:

```text
terraform.tfstate
```

It helps Terraform determine which resources it manages and calculate changes.

State is not the same as the Terraform configuration, and it is not a full backup of the deployed infrastructure.

### 7.2 Why does `terraform state list` show two entries?

This project contains two different tracked objects:

```text
data.aws_ssm_parameter.ubuntu
aws_instance.web_ec2
```

They are two entries in the same state, not two state files.

**Data source:**

```text
data.aws_ssm_parameter.ubuntu
```

- Reads information from SSM Parameter Store.
- Supplies the Ubuntu AMI ID.
- Does not create or delete the SSM parameter.

**Managed resource:**

```text
aws_instance.web_ec2
```

- Represents the EC2 instance managed by Terraform.
- Can be created, updated, or destroyed by Terraform.

### 7.3 Inspect a single state object

Inspect the data source:

```bash
terraform state show data.aws_ssm_parameter.ubuntu
```

Inspect the EC2 resource:

```bash
terraform state show aws_instance.web_ec2
```

**Why use `terraform state show`?**

It displays one specific object by its Terraform address.

This command is incorrect for selecting an object:

```bash
terraform show data.aws_ssm_parameter.ubuntu
```

Terraform interprets the extra argument as a state or plan file path. Use `terraform state show` when you want to inspect one object.

### 7.4 What is `terraform.tfstate.backup`?

With the local backend, Terraform can create `terraform.tfstate.backup` as a backup of a previous state file when updating state.

| File | Meaning |
|---|---|
| `terraform.tfstate` | Current local Terraform state. |
| `terraform.tfstate.backup` | Backup of an earlier local state, if created. |

A backup can be useful when recovering from an accidental state-file change. However, manually restoring state requires care because it may no longer match the actual infrastructure.

**Important:** A state backup does not back up the EC2 instance or its disk data. It only backs up state information.

### 7.5 What changes after `terraform destroy`?

After a successful destruction:

- The EC2 instance is terminated in AWS.
- The EC2 resource entry is removed from state.
- The local state file usually remains.
- The Terraform configuration files remain unchanged.
- The SSM parameter is not deleted by this project because it is read through a data source.

The exact state contents depend on the resources and backend involved.

### 7.6 State security

State files can contain sensitive values.

Do not commit these files to a public Git repository. For team and production environments, use a properly secured remote backend, access controls, encryption, and state locking where supported.

---

## 8. Updating and Destroying Infrastructure

### 8.1 Updating the EC2 instance

Change a value in the configuration or variable file, then run:

```bash
terraform plan
terraform apply
```

**Why?**

The plan shows whether the change requires an in-place update, replacement, or another action. The apply executes the approved changes.

Not all EC2 changes can be applied in place. Some changes require replacing the instance.

### 8.2 Destroying the EC2 instance

```bash
terraform destroy
```

**Why?**

This is used to remove infrastructure managed by the current Terraform configuration and state.

Terraform presents a destruction plan and asks for confirmation. Review the plan carefully before typing `yes`.

For this project, the EC2 instance is terminated after successful destruction.

**What is not deleted?**

- Terraform `.tf` configuration files.
- `README.md`.
- Git history and repository.
- The public SSM parameter and Ubuntu AMI read by the data source.

The state is updated to reflect the removal of the managed EC2 resource.

**Warning:** Terminating an instance can cause downtime and data loss. A retained EBS volume, if configured, may behave differently from the root volume in this example. Always review the plan and storage settings before destroying production infrastructure.

### 8.3 Recreating the infrastructure

If you want the infrastructure again and the configuration and permissions remain valid:

```bash
terraform plan
terraform apply
```

Terraform can create the infrastructure described by the configuration.

---

## 9. Understanding `.gitignore`

### Why do we need `.gitignore`?

Terraform generates local working files, state files, and sometimes saved plans. Some contain sensitive information or machine-specific data that should not be committed to Git.

Recommended `.gitignore`:

```gitignore
# Terraform working directory
.terraform/

# State files and state backups
*.tfstate
*.tfstate.*

# Saved execution plans
*.tfplan
tfplan

# Local variable files (may contain sensitive values)
terraform.tfvars
*.auto.tfvars
*.auto.tfvars.json

# Local backup files
*.backup
```

### What should be committed?

Normally commit:

- `.tf` configuration files.
- `README.md`.
- `.gitignore`.
- `.terraform.lock.hcl`.

The lock file should usually be committed so the team uses consistent provider selections.

### What should not be committed?

Normally exclude:

- `terraform.tfstate`
- `terraform.tfstate.backup`
- `.terraform/`
- Saved plans such as `tfplan`
- Sensitive local variable files
- AWS credentials and private keys

**Important:** `.gitignore` does not remove files already tracked by Git. If a state file was committed previously, it must be untracked separately. If credentials or secrets were exposed, revoke or rotate them as appropriate.

Before pushing, inspect tracked files:

```bash
git status --short
git ls-files
```

**Why?**

These commands help identify changes and files already tracked by Git. Verify that state files and sensitive values are not included.

---

## 10. Git and GitHub Workflow

### Step 1: Check the working tree

```bash
git status
```

**Why?**

It shows modified, untracked, and staged files.

### Step 2: Check the current branch

```bash
git branch
```

**Why?**

It shows local branches and identifies the current branch.

### Step 3: Check the remote repository

```bash
git remote -v
```

**Why?**

It displays configured Git remotes, such as a GitHub repository.

### Step 4: Create a feature branch

```bash
git switch -c docs/terraform-readme
```

**Why?**

It creates a separate branch for the documentation change, keeping the work isolated from the main branch.

### Step 5: Stage the intended files

```bash
git add README.md .gitignore
```

**Why?**

It stages only the specified files for the next commit. Review the staged changes before committing.

### Step 6: Review staged changes

```bash
git diff --cached
```

**Why?**

It shows exactly what will be included in the commit.

### Step 7: Commit the changes

```bash
git commit -m "docs: improve Terraform EC2 README"
```

**Why?**

A commit records a snapshot of the staged changes in Git history.

### Step 8: Push the branch

```bash
git push -u origin docs/terraform-readme
```

**Why?**

It pushes the branch to the configured remote named `origin`. Confirm that the remote is correct before pushing.

### Step 9: Open a pull request

Create a pull request on GitHub from `docs/terraform-readme` into the intended base branch, review the changes, and merge after approval.

**Why?**

Pull requests provide a place to review changes before integrating them into the main branch.

If the repository does not have a remote configured, add the correct GitHub remote before pushing. Never assume the remote URL.

---

## 11. Terraform Command Reference

| Command | Why we use it |
|---|---|
| `terraform version` | Check the installed Terraform version. |
| `terraform init` | Initialize the directory and download providers. |
| `terraform fmt` | Format configuration files. |
| `terraform validate` | Check configuration syntax and consistency. |
| `terraform plan` | Preview proposed infrastructure changes. |
| `terraform apply` | Apply the approved changes. |
| `terraform state list` | List objects in the current state. |
| `terraform state show ADDRESS` | Inspect one state object. |
| `terraform show` | Display the current state or a saved plan. |
| `terraform output` | Display declared outputs. |
| `terraform destroy` | Plan and remove managed infrastructure. |
| `terraform providers` | Show provider requirements. |
| `terraform graph` | Generate a dependency graph representation. |

Always check the plan before applying or destroying important infrastructure.

---

## 12. Troubleshooting

### Error: AWS access denied

**Possible reason:** The configured IAM identity does not have permission to perform the required API action.

**What to do:**

1. Verify the identity with `aws sts get-caller-identity --profile dev`.
2. Read the exact denied API action in the error.
3. Request the minimum required permission.
4. Retry after permissions are corrected.

Do not solve access errors by granting broad administrator permissions unnecessarily.

### Error: `terraform output` says no outputs found

**Possible reason:** No output blocks are declared.

**What to do:** Add appropriate output blocks to `outputs.tf`, then run `terraform apply` and `terraform output`.

### Error: `terraform show ADDRESS` cannot find a file

**Possible reason:** `terraform show` expects a state or saved plan file path, not a resource address.

**Correct command:**

```bash
terraform state show aws_instance.web_ec2
```

### Error: Terraform wants to change or replace an EC2 instance

**Possible reason:** A configuration value changed or the provider requires replacement for that attribute.

**What to do:** Review the plan carefully. Understand which attributes are changing and whether the instance will be replaced before approving the operation.

### Error: `.gitignore` is not hiding a state file

**Possible reason:** The file was already tracked by Git.

**What to do:** Confirm tracking with `git ls-files`, then untrack the file appropriately. Do not accidentally publish state or secrets.

---

## 13. Interview Questions and Answers

### Q1. What is Terraform?

Terraform is an Infrastructure as Code tool that lets us define, provision, and manage infrastructure using configuration files.

### Q2. What is a Terraform provider?

A provider allows Terraform to interact with a platform through its APIs. The AWS provider lets Terraform manage AWS resources.

### Q3. What is the difference between a data source and a resource?

A data source reads information about an existing object. A resource manages infrastructure through Terraform. In this project, SSM provides the AMI ID and the EC2 resource creates the instance.

### Q4. Why do we use variables?

Variables make configuration reusable and reduce hardcoding. They allow values such as region and instance type to be supplied separately from the resource definitions.

### Q5. What is Terraform state?

State records information Terraform uses to map configuration objects to real infrastructure. It helps Terraform determine which changes are needed.

### Q6. Why does `terraform state list` show two entries?

Because the project tracks an SSM data source and an EC2 resource. They are two objects in one state, not two state files.

### Q7. What is `terraform.tfstate.backup`?

It is a backup of an earlier local state file when Terraform creates one. It is not an infrastructure or disk-data backup.

### Q8. What happens when you run `terraform destroy`?

Terraform prepares a plan to remove the managed resources. After approval, it destroys them through the provider APIs and updates state to reflect the removal. The configuration files remain.

### Q9. Does `terraform destroy` delete the state file?

Not necessarily. With the local backend, the state file usually remains, but the destroyed resource entries are removed. Remote backends have their own state storage behavior.

### Q10. Does Terraform delete the SSM parameter during destroy?

No. The project reads the parameter through a data source. It does not manage that parameter as a resource.

### Q11. What is idempotency?

It means repeatedly applying an unchanged configuration should not continue making unnecessary changes once the infrastructure matches the desired configuration.

### Q12. What is the difference between `terraform plan` and `terraform apply`?

`plan` previews proposed changes. `apply` executes the changes after the plan is reviewed and approved.

### Q13. Why should we not commit state files to Git?

State can contain sensitive information and infrastructure details. It should be protected with appropriate access controls and stored securely.

### Q14. Why commit `.terraform.lock.hcl`?

It records selected provider versions and checksums so other developers can install consistent provider versions.

### Q15. What is `.gitignore`?

It tells Git which matching untracked files to ignore. It does not automatically remove files that are already tracked.

### Q16. Can Terraform recreate an instance after destroy?

Yes. If the configuration, provider access, and dependencies are valid, `terraform apply` can create the infrastructure again.

### Q17. Is Terraform state a backup?

No. State tracks infrastructure; it does not preserve the infrastructure or its disk data. It must be secured and backed up separately as appropriate.

### Q18. What should you check before running `terraform destroy` in production?

I would review the destruction plan, confirm the target workspace and backend, understand resource dependencies, assess potential downtime and data loss, and obtain the required approval.

---

## 14. Best Practices

- Use version control for Terraform configuration and documentation.
- Commit `.terraform.lock.hcl`.
- Exclude state files, saved plans, credentials, and sensitive local values from Git.
- Never hardcode AWS access keys in Terraform configuration.
- Use least-privilege IAM permissions.
- Prefer appropriate short-lived credentials or IAM roles for production.
- Review `terraform plan` before applying or destroying infrastructure.
- Use a secured remote backend and state locking where supported for team environments.
- Protect state files because they may contain sensitive values.
- Use descriptive resource names and tags.
- Separate development, testing, and production environments appropriately.
- Document commands and important design decisions in the README.

---

## Project Summary

This project demonstrates the fundamentals of Terraform and AWS through an EC2 deployment. It covers provider configuration, variables, SSM-based AMI lookup, resource management, state inspection, destruction, and Git practices.

The same fundamentals form the foundation for larger Terraform projects involving custom VPCs, public and private subnets, security groups, load balancers, S3, remote state, and state locking.