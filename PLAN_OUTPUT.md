# PLAN_OUTPUT

Salidas reales de la validación del entorno `environments/dev` contra LocalStack, copiadas sin editar. Se omitió solo el aviso de deprecación que `tflocal` imprime por stderr antes de cada comando (recomienda migrar a `lstk terraform`).

Fecha de ejecución: 2026-11-20.

## Índice

1. [Versiones](#1-versiones)
2. [tflocal validate](#2-tflocal-validate)
3. [tflint](#3-tflint)
4. [tflocal plan](#4-tflocal-plan)
5. [tflocal apply](#5-tflocal-apply)
6. [describe-vpc-endpoints](#6-aws-ec2-describe-vpc-endpoints)
7. [Verificaciones extra de la red](#7-verificaciones-extra-de-la-red)
8. [State remoto y segundo plan](#8-state-remoto-y-segundo-plan)

## 1. Versiones

```text
Terraform v1.17.1
on windows_amd64
aws-cli/2.41.2 Python/3.14.10 Windows/11 exe/AMD64
TFLint version 0.65.0
Version: 0.27.0
LocalStack 2026.10.8 pro
```

## 2. tflocal validate

Comando (en `environments/dev`): `tflocal validate`

```text
Success! The configuration is valid.
```

## 3. tflint

Comando (en la raíz): `tflint --recursive`. Sin salida y con código de salida 0: no hay hallazgos con el preset `all` del ruleset de Terraform.

```text
(sin salida, exit code 0)
```

## 4. tflocal plan

Comando: `tflocal plan`

> El warning `Deprecated Parameter` se refiere a `dynamodb_table` en el backend. Desde Terraform 1.11 se recomienda `use_lockfile` (lock nativo en S3); se mantiene DynamoDB porque lo pide la consigna.

```text

Warning: Deprecated Parameter

The parameter "dynamodb_table" is deprecated. Use parameter "use_lockfile"
instead.
data.aws_availability_zones.available: Reading...
module.identity.data.aws_partition.current: Reading...
module.identity.data.aws_caller_identity.current: Reading...
module.network.data.aws_region.current: Reading...
data.aws_caller_identity.current: Reading...
module.identity.data.aws_partition.current: Read complete after 0s [id=aws]
module.network.data.aws_region.current: Read complete after 0s [id=us-east-1]
data.aws_caller_identity.current: Read complete after 0s [id=000000000000]
data.aws_availability_zones.available: Read complete after 0s [id=us-east-1]
module.identity.data.aws_caller_identity.current: Read complete after 0s [id=000000000000]
module.identity.data.aws_iam_policy_document.processing_trust: Reading...
module.identity.data.aws_iam_policy_document.audit_trust: Reading...
module.identity.data.aws_iam_policy_document.audit_trust: Read complete after 0s [id=1734375019]
module.identity.data.aws_iam_policy_document.processing_trust: Read complete after 0s [id=1655673507]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create
 <= read (data resources)

Terraform will perform the following actions:

  # aws_s3_bucket.data_lake will be created
  + resource "aws_s3_bucket" "data_lake" {
      + acceleration_status         = (known after apply)
      + acl                         = (known after apply)
      + arn                         = (known after apply)
      + bucket                      = "dataplat-dev-lake-000000000000"
      + bucket_domain_name          = (known after apply)
      + bucket_namespace            = (known after apply)
      + bucket_prefix               = (known after apply)
      + bucket_region               = (known after apply)
      + bucket_regional_domain_name = (known after apply)
      + force_destroy               = true
      + hosted_zone_id              = (known after apply)
      + id                          = (known after apply)
      + object_lock_enabled         = (known after apply)
      + policy                      = (known after apply)
      + region                      = "us-east-1"
      + request_payer               = (known after apply)
      + tags                        = {
          + "Name" = "dataplat-dev-lake"
        }
      + tags_all                    = {
          + "CostCenter"  = "data-platform"
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Name"        = "dataplat-dev-lake"
          + "Owner"       = "data-engineering"
          + "Project"     = "dataplat"
        }
      + website_domain              = (known after apply)
      + website_endpoint            = (known after apply)

      + cors_rule (known after apply)

      + grant (known after apply)

      + lifecycle_rule (known after apply)

      + logging (known after apply)

      + object_lock_configuration (known after apply)

      + replication_configuration (known after apply)

      + server_side_encryption_configuration (known after apply)

      + versioning (known after apply)

      + website (known after apply)
    }

  # aws_s3_bucket_lifecycle_configuration.data_lake will be created
  + resource "aws_s3_bucket_lifecycle_configuration" "data_lake" {
      + bucket                                 = (known after apply)
      + expected_bucket_owner                  = (known after apply)
      + id                                     = (known after apply)
      + region                                 = "us-east-1"
      + transition_default_minimum_object_size = "all_storage_classes_128K"

      + rule {
          + id     = "expire-raw-data"
          + status = "Enabled"
            # (1 unchanged attribute hidden)

          + expiration {
              + days                         = 30
              + expired_object_delete_marker = false
            }

          + filter {
              + prefix = "raw/"
            }

          + noncurrent_version_expiration {
              + noncurrent_days = 30
            }
        }
    }

  # aws_s3_bucket_public_access_block.data_lake will be created
  + resource "aws_s3_bucket_public_access_block" "data_lake" {
      + block_public_acls       = true
      + block_public_policy     = true
      + bucket                  = (known after apply)
      + id                      = (known after apply)
      + ignore_public_acls      = true
      + region                  = "us-east-1"
      + restrict_public_buckets = true
    }

  # aws_s3_bucket_server_side_encryption_configuration.data_lake will be created
  + resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
      + bucket = (known after apply)
      + id     = (known after apply)
      + region = "us-east-1"

      + rule {
          + blocked_encryption_types = (known after apply)
          + bucket_key_enabled       = (known after apply)

          + apply_server_side_encryption_by_default {
              + kms_master_key_id = (known after apply)
              + sse_algorithm     = "AES256"
            }
        }
    }

  # aws_s3_bucket_versioning.data_lake will be created
  + resource "aws_s3_bucket_versioning" "data_lake" {
      + bucket = (known after apply)
      + id     = (known after apply)
      + region = "us-east-1"

      + versioning_configuration {
          + mfa_delete = (known after apply)
          + status     = "Enabled"
        }
    }

  # module.identity.data.aws_iam_policy_document.audit_permissions will be read during apply
  # (config refers to values not yet known)
 <= data "aws_iam_policy_document" "audit_permissions" {
      + id            = (known after apply)
      + json          = (known after apply)
      + minified_json = (known after apply)

      + statement {
          + actions   = [
              + "s3:GetBucketLocation",
              + "s3:GetBucketLogging",
              + "s3:GetBucketPolicy",
              + "s3:GetBucketPolicyStatus",
              + "s3:GetBucketPublicAccessBlock",
              + "s3:GetBucketTagging",
              + "s3:GetBucketVersioning",
              + "s3:GetEncryptionConfiguration",
              + "s3:GetLifecycleConfiguration",
            ]
          + effect    = "Allow"
          + resources = [
              + (known after apply),
            ]
          + sid       = "ReadDataLakeBucketConfiguration"
        }
      + statement {
          + actions   = [
              + "iam:GetRole",
              + "iam:GetRolePolicy",
              + "iam:ListAttachedRolePolicies",
              + "iam:ListRolePolicies",
              + "iam:ListRoleTags",
            ]
          + effect    = "Allow"
          + resources = [
              + (known after apply),
              + (known after apply),
            ]
          + sid       = "ReadPlatformRolesConfiguration"
        }
    }

  # module.identity.data.aws_iam_policy_document.processing_permissions will be read during apply
  # (config refers to values not yet known)
 <= data "aws_iam_policy_document" "processing_permissions" {
      + id            = (known after apply)
      + json          = (known after apply)
      + minified_json = (known after apply)

      + statement {
          + actions   = [
              + "s3:ListBucket",
            ]
          + effect    = "Allow"
          + resources = [
              + (known after apply),
            ]
          + sid       = "ListOnlyProcessingPrefix"

          + condition {
              + test     = "StringLike"
              + values   = [
                  + "processed/",
                  + "processed/*",
                ]
              + variable = "s3:prefix"
            }
        }
      + statement {
          + actions   = [
              + "s3:GetObject",
              + "s3:PutObject",
            ]
          + effect    = "Allow"
          + resources = [
              + (known after apply),
            ]
          + sid       = "ReadWriteObjectsInProcessingPrefix"
        }
    }

  # module.identity.aws_iam_role.audit will be created
  + resource "aws_iam_role" "audit" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Condition = {
                          + Bool = {
                              + "aws:MultiFactorAuthPresent" = "true"
                            }
                        }
                      + Effect    = "Allow"
                      + Principal = {
                          + AWS = "arn:aws:iam::000000000000:root"
                        }
                      + Sid       = "AllowAuditorsToAssume"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + description           = "Rol de plano de control de solo lectura para auditar la configuración de la plataforma"
      + force_detach_policies = false
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = "dataplat-dev-audit-readonly"
      + name_prefix           = (known after apply)
      + path                  = "/"
      + tags                  = {
          + "Name" = "dataplat-dev-audit-readonly"
          + "Role" = "audit"
        }
      + tags_all              = {
          + "CostCenter"  = "data-platform"
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Name"        = "dataplat-dev-audit-readonly"
          + "Owner"       = "data-engineering"
          + "Project"     = "dataplat"
          + "Role"        = "audit"
        }
      + unique_id             = (known after apply)

      + inline_policy (known after apply)
    }

  # module.identity.aws_iam_role.processing will be created
  + resource "aws_iam_role" "processing" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Condition = {
                          + StringEquals = {
                              + "aws:SourceAccount" = "000000000000"
                            }
                        }
                      + Effect    = "Allow"
                      + Principal = {
                          + Service = [
                              + "lambda.amazonaws.com",
                              + "kinesisanalytics.amazonaws.com",
                            ]
                        }
                      + Sid       = "AllowDataServicesToAssume"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + description           = "Rol de procesamiento (Lambda/Flink): lectura y escritura solo en s3://<data-lake>/processed/"
      + force_detach_policies = false
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = "dataplat-dev-processing"
      + name_prefix           = (known after apply)
      + path                  = "/"
      + tags                  = {
          + "Name" = "dataplat-dev-processing"
          + "Role" = "processing"
        }
      + tags_all              = {
          + "CostCenter"  = "data-platform"
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Name"        = "dataplat-dev-processing"
          + "Owner"       = "data-engineering"
          + "Project"     = "dataplat"
          + "Role"        = "processing"
        }
      + unique_id             = (known after apply)

      + inline_policy (known after apply)
    }

  # module.identity.aws_iam_role_policy.audit will be created
  + resource "aws_iam_role_policy" "audit" {
      + id          = (known after apply)
      + name        = "dataplat-dev-audit-readonly"
      + name_prefix = (known after apply)
      + policy      = (known after apply)
      + role        = (known after apply)
    }

  # module.identity.aws_iam_role_policy.processing will be created
  + resource "aws_iam_role_policy" "processing" {
      + id          = (known after apply)
      + name        = "dataplat-dev-processing-s3-prefix"
      + name_prefix = (known after apply)
      + policy      = (known after apply)
      + role        = (known after apply)
    }

  # module.network.aws_default_security_group.this will be created
  + resource "aws_default_security_group" "this" {
      + arn                    = (known after apply)
      + description            = (known after apply)
      + egress                 = (known after apply)
      + id                     = (known after apply)
      + ingress                = (known after apply)
      + name                   = (known after apply)
      + name_prefix            = (known after apply)
      + owner_id               = (known after apply)
      + region                 = "us-east-1"
      + revoke_rules_on_delete = false
      + tags                   = {
          + "Name" = "dataplat-dev-default-sg-deny-all"
        }
      + tags_all               = {
          + "CostCenter"  = "data-platform"
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Name"        = "dataplat-dev-default-sg-deny-all"
          + "Owner"       = "data-engineering"
          + "Project"     = "dataplat"
        }
      + vpc_id                 = (known after apply)
    }

  # module.network.aws_route_table.private["us-east-1a"] will be created
  + resource "aws_route_table" "private" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + region           = "us-east-1"
      + route            = (known after apply)
      + tags             = {
          + "Name" = "dataplat-dev-private-rt-us-east-1a"
          + "Tier" = "private"
        }
      + tags_all         = {
          + "CostCenter"  = "data-platform"
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Name"        = "dataplat-dev-private-rt-us-east-1a"
          + "Owner"       = "data-engineering"
          + "Project"     = "dataplat"
          + "Tier"        = "private"
        }
      + vpc_id           = (known after apply)
    }

  # module.network.aws_route_table.private["us-east-1b"] will be created
  + resource "aws_route_table" "private" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + region           = "us-east-1"
      + route            = (known after apply)
      + tags             = {
          + "Name" = "dataplat-dev-private-rt-us-east-1b"
          + "Tier" = "private"
        }
      + tags_all         = {
          + "CostCenter"  = "data-platform"
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Name"        = "dataplat-dev-private-rt-us-east-1b"
          + "Owner"       = "data-engineering"
          + "Project"     = "dataplat"
          + "Tier"        = "private"
        }
      + vpc_id           = (known after apply)
    }

  # module.network.aws_route_table_association.private["us-east-1a"] will be created
  + resource "aws_route_table_association" "private" {
      + id             = (known after apply)
      + region         = "us-east-1"
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.network.aws_route_table_association.private["us-east-1b"] will be created
  + resource "aws_route_table_association" "private" {
      + id             = (known after apply)
      + region         = "us-east-1"
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.network.aws_subnet.private["us-east-1a"] will be created
  + resource "aws_subnet" "private" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1a"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.10.0.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block                                = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + region                                         = "us-east-1"
      + tags                                           = {
          + "Name" = "dataplat-dev-private-us-east-1a"
          + "Tier" = "private"
        }
      + tags_all                                       = {
          + "CostCenter"  = "data-platform"
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Name"        = "dataplat-dev-private-us-east-1a"
          + "Owner"       = "data-engineering"
          + "Project"     = "dataplat"
          + "Tier"        = "private"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.network.aws_subnet.private["us-east-1b"] will be created
  + resource "aws_subnet" "private" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1b"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.10.1.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block                                = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + region                                         = "us-east-1"
      + tags                                           = {
          + "Name" = "dataplat-dev-private-us-east-1b"
          + "Tier" = "private"
        }
      + tags_all                                       = {
          + "CostCenter"  = "data-platform"
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Name"        = "dataplat-dev-private-us-east-1b"
          + "Owner"       = "data-engineering"
          + "Project"     = "dataplat"
          + "Tier"        = "private"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.network.aws_vpc.this will be created
  + resource "aws_vpc" "this" {
      + arn                                  = (known after apply)
      + cidr_block                           = "10.10.0.0/16"
      + default_network_acl_id               = (known after apply)
      + default_route_table_id               = (known after apply)
      + default_security_group_id            = (known after apply)
      + dhcp_options_id                      = (known after apply)
      + enable_dns_hostnames                 = true
      + enable_dns_support                   = true
      + enable_network_address_usage_metrics = (known after apply)
      + id                                   = (known after apply)
      + instance_tenancy                     = "default"
      + ipv6_association_id                  = (known after apply)
      + ipv6_cidr_block                      = (known after apply)
      + ipv6_cidr_block_network_border_group = (known after apply)
      + main_route_table_id                  = (known after apply)
      + owner_id                             = (known after apply)
      + region                               = "us-east-1"
      + tags                                 = {
          + "Name" = "dataplat-dev-vpc"
        }
      + tags_all                             = {
          + "CostCenter"  = "data-platform"
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Name"        = "dataplat-dev-vpc"
          + "Owner"       = "data-engineering"
          + "Project"     = "dataplat"
        }
    }

  # module.network.aws_vpc_endpoint.s3 will be created
  + resource "aws_vpc_endpoint" "s3" {
      + arn                   = (known after apply)
      + cidr_blocks           = (known after apply)
      + dns_entry             = (known after apply)
      + id                    = (known after apply)
      + ip_address_type       = (known after apply)
      + network_interface_ids = (known after apply)
      + owner_id              = (known after apply)
      + policy                = (known after apply)
      + prefix_list_id        = (known after apply)
      + private_dns_enabled   = (known after apply)
      + region                = "us-east-1"
      + requester_managed     = (known after apply)
      + route_table_ids       = (known after apply)
      + security_group_ids    = (known after apply)
      + service_name          = "com.amazonaws.us-east-1.s3"
      + service_region        = (known after apply)
      + state                 = (known after apply)
      + subnet_ids            = (known after apply)
      + tags                  = {
          + "Name" = "dataplat-dev-s3-gateway-endpoint"
        }
      + tags_all              = {
          + "CostCenter"  = "data-platform"
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Name"        = "dataplat-dev-s3-gateway-endpoint"
          + "Owner"       = "data-engineering"
          + "Project"     = "dataplat"
        }
      + vpc_endpoint_type     = "Gateway"
      + vpc_id                = (known after apply)

      + dns_options (known after apply)

      + subnet_configuration (known after apply)
    }

Plan: 18 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + audit_role_arn        = (known after apply)
  + data_lake_bucket_arn  = (known after apply)
  + data_lake_bucket_name = "dataplat-dev-lake-000000000000"
  + private_subnet_ids    = [
      + (known after apply),
      + (known after apply),
    ]
  + processing_role_arn   = (known after apply)
  + s3_vpc_endpoint_id    = (known after apply)
  + vpc_id                = (known after apply)

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
```

## 5. tflocal apply

Comando: `tflocal apply -auto-approve`

```text

Warning: Deprecated Parameter

The parameter "dynamodb_table" is deprecated. Use parameter "use_lockfile"
instead.
data.aws_availability_zones.available: Reading...
module.identity.data.aws_caller_identity.current: Reading...
data.aws_caller_identity.current: Reading...
module.identity.data.aws_partition.current: Reading...
module.network.data.aws_region.current: Reading...
module.identity.data.aws_partition.current: Read complete after 0s [id=aws]
module.network.data.aws_region.current: Read complete after 0s [id=us-east-1]
module.identity.data.aws_caller_identity.current: Read complete after 0s [id=000000000000]
data.aws_availability_zones.available: Read complete after 0s [id=us-east-1]
module.identity.data.aws_iam_policy_document.processing_trust: Reading...
module.identity.data.aws_iam_policy_document.audit_trust: Reading...
module.identity.data.aws_iam_policy_document.audit_trust: Read complete after 0s [id=1734375019]
module.identity.data.aws_iam_policy_document.processing_trust: Read complete after 0s [id=1655673507]
data.aws_caller_identity.current: Read complete after 0s [id=000000000000]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create
 <= read (data resources)

Terraform will perform the following actions:

  # aws_s3_bucket.data_lake will be created
  + resource "aws_s3_bucket" "data_lake" {
      + acceleration_status         = (known after apply)
      + acl                         = (known after apply)
      + arn                         = (known after apply)
      + bucket                      = "dataplat-dev-lake-000000000000"
      + bucket_domain_name          = (known after apply)
      + bucket_namespace            = (known after apply)
      + bucket_prefix               = (known after apply)
      + bucket_region               = (known after apply)
      + bucket_regional_domain_name = (known after apply)
      + force_destroy               = true
      + hosted_zone_id              = (known after apply)
      + id                          = (known after apply)
      + object_lock_enabled         = (known after apply)
      + policy                      = (known after apply)
      + region                      = "us-east-1"
      + request_payer               = (known after apply)
      + tags                        = {
          + "Name" = "dataplat-dev-lake"
        }
      + tags_all                    = {
          + "CostCenter"  = "data-platform"
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Name"        = "dataplat-dev-lake"
          + "Owner"       = "data-engineering"
          + "Project"     = "dataplat"
        }
      + website_domain              = (known after apply)
      + website_endpoint            = (known after apply)

      + cors_rule (known after apply)

      + grant (known after apply)

      + lifecycle_rule (known after apply)

      + logging (known after apply)

      + object_lock_configuration (known after apply)

      + replication_configuration (known after apply)

      + server_side_encryption_configuration (known after apply)

      + versioning (known after apply)

      + website (known after apply)
    }

  # aws_s3_bucket_lifecycle_configuration.data_lake will be created
  + resource "aws_s3_bucket_lifecycle_configuration" "data_lake" {
      + bucket                                 = (known after apply)
      + expected_bucket_owner                  = (known after apply)
      + id                                     = (known after apply)
      + region                                 = "us-east-1"
      + transition_default_minimum_object_size = "all_storage_classes_128K"

      + rule {
          + id     = "expire-raw-data"
          + status = "Enabled"
            # (1 unchanged attribute hidden)

          + expiration {
              + days                         = 30
              + expired_object_delete_marker = false
            }

          + filter {
              + prefix = "raw/"
            }

          + noncurrent_version_expiration {
              + noncurrent_days = 30
            }
        }
    }

  # aws_s3_bucket_public_access_block.data_lake will be created
  + resource "aws_s3_bucket_public_access_block" "data_lake" {
      + block_public_acls       = true
      + block_public_policy     = true
      + bucket                  = (known after apply)
      + id                      = (known after apply)
      + ignore_public_acls      = true
      + region                  = "us-east-1"
      + restrict_public_buckets = true
    }

  # aws_s3_bucket_server_side_encryption_configuration.data_lake will be created
  + resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
      + bucket = (known after apply)
      + id     = (known after apply)
      + region = "us-east-1"

      + rule {
          + blocked_encryption_types = (known after apply)
          + bucket_key_enabled       = (known after apply)

          + apply_server_side_encryption_by_default {
              + kms_master_key_id = (known after apply)
              + sse_algorithm     = "AES256"
            }
        }
    }

  # aws_s3_bucket_versioning.data_lake will be created
  + resource "aws_s3_bucket_versioning" "data_lake" {
      + bucket = (known after apply)
      + id     = (known after apply)
      + region = "us-east-1"

      + versioning_configuration {
          + mfa_delete = (known after apply)
          + status     = "Enabled"
        }
    }

  # module.identity.data.aws_iam_policy_document.audit_permissions will be read during apply
  # (config refers to values not yet known)
 <= data "aws_iam_policy_document" "audit_permissions" {
      + id            = (known after apply)
      + json          = (known after apply)
      + minified_json = (known after apply)

      + statement {
          + actions   = [
              + "s3:GetBucketLocation",
              + "s3:GetBucketLogging",
              + "s3:GetBucketPolicy",
              + "s3:GetBucketPolicyStatus",
              + "s3:GetBucketPublicAccessBlock",
              + "s3:GetBucketTagging",
              + "s3:GetBucketVersioning",
              + "s3:GetEncryptionConfiguration",
              + "s3:GetLifecycleConfiguration",
            ]
          + effect    = "Allow"
          + resources = [
              + (known after apply),
            ]
          + sid       = "ReadDataLakeBucketConfiguration"
        }
      + statement {
          + actions   = [
              + "iam:GetRole",
              + "iam:GetRolePolicy",
              + "iam:ListAttachedRolePolicies",
              + "iam:ListRolePolicies",
              + "iam:ListRoleTags",
            ]
          + effect    = "Allow"
          + resources = [
              + (known after apply),
              + (known after apply),
            ]
          + sid       = "ReadPlatformRolesConfiguration"
        }
    }

  # module.identity.data.aws_iam_policy_document.processing_permissions will be read during apply
  # (config refers to values not yet known)
 <= data "aws_iam_policy_document" "processing_permissions" {
      + id            = (known after apply)
      + json          = (known after apply)
      + minified_json = (known after apply)

      + statement {
          + actions   = [
              + "s3:ListBucket",
            ]
          + effect    = "Allow"
          + resources = [
              + (known after apply),
            ]
          + sid       = "ListOnlyProcessingPrefix"

          + condition {
              + test     = "StringLike"
              + values   = [
                  + "processed/",
                  + "processed/*",
                ]
              + variable = "s3:prefix"
            }
        }
      + statement {
          + actions   = [
              + "s3:GetObject",
              + "s3:PutObject",
            ]
          + effect    = "Allow"
          + resources = [
              + (known after apply),
            ]
          + sid       = "ReadWriteObjectsInProcessingPrefix"
        }
    }

  # module.identity.aws_iam_role.audit will be created
  + resource "aws_iam_role" "audit" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Condition = {
                          + Bool = {
                              + "aws:MultiFactorAuthPresent" = "true"
                            }
                        }
                      + Effect    = "Allow"
                      + Principal = {
                          + AWS = "arn:aws:iam::000000000000:root"
                        }
                      + Sid       = "AllowAuditorsToAssume"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + description           = "Rol de plano de control de solo lectura para auditar la configuración de la plataforma"
      + force_detach_policies = false
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = "dataplat-dev-audit-readonly"
      + name_prefix           = (known after apply)
      + path                  = "/"
      + tags                  = {
          + "Name" = "dataplat-dev-audit-readonly"
          + "Role" = "audit"
        }
      + tags_all              = {
          + "CostCenter"  = "data-platform"
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Name"        = "dataplat-dev-audit-readonly"
          + "Owner"       = "data-engineering"
          + "Project"     = "dataplat"
          + "Role"        = "audit"
        }
      + unique_id             = (known after apply)

      + inline_policy (known after apply)
    }

  # module.identity.aws_iam_role.processing will be created
  + resource "aws_iam_role" "processing" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Condition = {
                          + StringEquals = {
                              + "aws:SourceAccount" = "000000000000"
                            }
                        }
                      + Effect    = "Allow"
                      + Principal = {
                          + Service = [
                              + "lambda.amazonaws.com",
                              + "kinesisanalytics.amazonaws.com",
                            ]
                        }
                      + Sid       = "AllowDataServicesToAssume"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + description           = "Rol de procesamiento (Lambda/Flink): lectura y escritura solo en s3://<data-lake>/processed/"
      + force_detach_policies = false
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = "dataplat-dev-processing"
      + name_prefix           = (known after apply)
      + path                  = "/"
      + tags                  = {
          + "Name" = "dataplat-dev-processing"
          + "Role" = "processing"
        }
      + tags_all              = {
          + "CostCenter"  = "data-platform"
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Name"        = "dataplat-dev-processing"
          + "Owner"       = "data-engineering"
          + "Project"     = "dataplat"
          + "Role"        = "processing"
        }
      + unique_id             = (known after apply)

      + inline_policy (known after apply)
    }

  # module.identity.aws_iam_role_policy.audit will be created
  + resource "aws_iam_role_policy" "audit" {
      + id          = (known after apply)
      + name        = "dataplat-dev-audit-readonly"
      + name_prefix = (known after apply)
      + policy      = (known after apply)
      + role        = (known after apply)
    }

  # module.identity.aws_iam_role_policy.processing will be created
  + resource "aws_iam_role_policy" "processing" {
      + id          = (known after apply)
      + name        = "dataplat-dev-processing-s3-prefix"
      + name_prefix = (known after apply)
      + policy      = (known after apply)
      + role        = (known after apply)
    }

  # module.network.aws_default_security_group.this will be created
  + resource "aws_default_security_group" "this" {
      + arn                    = (known after apply)
      + description            = (known after apply)
      + egress                 = (known after apply)
      + id                     = (known after apply)
      + ingress                = (known after apply)
      + name                   = (known after apply)
      + name_prefix            = (known after apply)
      + owner_id               = (known after apply)
      + region                 = "us-east-1"
      + revoke_rules_on_delete = false
      + tags                   = {
          + "Name" = "dataplat-dev-default-sg-deny-all"
        }
      + tags_all               = {
          + "CostCenter"  = "data-platform"
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Name"        = "dataplat-dev-default-sg-deny-all"
          + "Owner"       = "data-engineering"
          + "Project"     = "dataplat"
        }
      + vpc_id                 = (known after apply)
    }

  # module.network.aws_route_table.private["us-east-1a"] will be created
  + resource "aws_route_table" "private" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + region           = "us-east-1"
      + route            = (known after apply)
      + tags             = {
          + "Name" = "dataplat-dev-private-rt-us-east-1a"
          + "Tier" = "private"
        }
      + tags_all         = {
          + "CostCenter"  = "data-platform"
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Name"        = "dataplat-dev-private-rt-us-east-1a"
          + "Owner"       = "data-engineering"
          + "Project"     = "dataplat"
          + "Tier"        = "private"
        }
      + vpc_id           = (known after apply)
    }

  # module.network.aws_route_table.private["us-east-1b"] will be created
  + resource "aws_route_table" "private" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + region           = "us-east-1"
      + route            = (known after apply)
      + tags             = {
          + "Name" = "dataplat-dev-private-rt-us-east-1b"
          + "Tier" = "private"
        }
      + tags_all         = {
          + "CostCenter"  = "data-platform"
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Name"        = "dataplat-dev-private-rt-us-east-1b"
          + "Owner"       = "data-engineering"
          + "Project"     = "dataplat"
          + "Tier"        = "private"
        }
      + vpc_id           = (known after apply)
    }

  # module.network.aws_route_table_association.private["us-east-1a"] will be created
  + resource "aws_route_table_association" "private" {
      + id             = (known after apply)
      + region         = "us-east-1"
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.network.aws_route_table_association.private["us-east-1b"] will be created
  + resource "aws_route_table_association" "private" {
      + id             = (known after apply)
      + region         = "us-east-1"
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.network.aws_subnet.private["us-east-1a"] will be created
  + resource "aws_subnet" "private" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1a"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.10.0.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block                                = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + region                                         = "us-east-1"
      + tags                                           = {
          + "Name" = "dataplat-dev-private-us-east-1a"
          + "Tier" = "private"
        }
      + tags_all                                       = {
          + "CostCenter"  = "data-platform"
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Name"        = "dataplat-dev-private-us-east-1a"
          + "Owner"       = "data-engineering"
          + "Project"     = "dataplat"
          + "Tier"        = "private"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.network.aws_subnet.private["us-east-1b"] will be created
  + resource "aws_subnet" "private" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1b"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.10.1.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block                                = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + region                                         = "us-east-1"
      + tags                                           = {
          + "Name" = "dataplat-dev-private-us-east-1b"
          + "Tier" = "private"
        }
      + tags_all                                       = {
          + "CostCenter"  = "data-platform"
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Name"        = "dataplat-dev-private-us-east-1b"
          + "Owner"       = "data-engineering"
          + "Project"     = "dataplat"
          + "Tier"        = "private"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.network.aws_vpc.this will be created
  + resource "aws_vpc" "this" {
      + arn                                  = (known after apply)
      + cidr_block                           = "10.10.0.0/16"
      + default_network_acl_id               = (known after apply)
      + default_route_table_id               = (known after apply)
      + default_security_group_id            = (known after apply)
      + dhcp_options_id                      = (known after apply)
      + enable_dns_hostnames                 = true
      + enable_dns_support                   = true
      + enable_network_address_usage_metrics = (known after apply)
      + id                                   = (known after apply)
      + instance_tenancy                     = "default"
      + ipv6_association_id                  = (known after apply)
      + ipv6_cidr_block                      = (known after apply)
      + ipv6_cidr_block_network_border_group = (known after apply)
      + main_route_table_id                  = (known after apply)
      + owner_id                             = (known after apply)
      + region                               = "us-east-1"
      + tags                                 = {
          + "Name" = "dataplat-dev-vpc"
        }
      + tags_all                             = {
          + "CostCenter"  = "data-platform"
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Name"        = "dataplat-dev-vpc"
          + "Owner"       = "data-engineering"
          + "Project"     = "dataplat"
        }
    }

  # module.network.aws_vpc_endpoint.s3 will be created
  + resource "aws_vpc_endpoint" "s3" {
      + arn                   = (known after apply)
      + cidr_blocks           = (known after apply)
      + dns_entry             = (known after apply)
      + id                    = (known after apply)
      + ip_address_type       = (known after apply)
      + network_interface_ids = (known after apply)
      + owner_id              = (known after apply)
      + policy                = (known after apply)
      + prefix_list_id        = (known after apply)
      + private_dns_enabled   = (known after apply)
      + region                = "us-east-1"
      + requester_managed     = (known after apply)
      + route_table_ids       = (known after apply)
      + security_group_ids    = (known after apply)
      + service_name          = "com.amazonaws.us-east-1.s3"
      + service_region        = (known after apply)
      + state                 = (known after apply)
      + subnet_ids            = (known after apply)
      + tags                  = {
          + "Name" = "dataplat-dev-s3-gateway-endpoint"
        }
      + tags_all              = {
          + "CostCenter"  = "data-platform"
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Name"        = "dataplat-dev-s3-gateway-endpoint"
          + "Owner"       = "data-engineering"
          + "Project"     = "dataplat"
        }
      + vpc_endpoint_type     = "Gateway"
      + vpc_id                = (known after apply)

      + dns_options (known after apply)

      + subnet_configuration (known after apply)
    }

Plan: 18 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + audit_role_arn        = (known after apply)
  + data_lake_bucket_arn  = (known after apply)
  + data_lake_bucket_name = "dataplat-dev-lake-000000000000"
  + private_subnet_ids    = [
      + (known after apply),
      + (known after apply),
    ]
  + processing_role_arn   = (known after apply)
  + s3_vpc_endpoint_id    = (known after apply)
  + vpc_id                = (known after apply)
module.identity.aws_iam_role.audit: Creating...
module.network.aws_vpc.this: Creating...
module.identity.aws_iam_role.processing: Creating...
aws_s3_bucket.data_lake: Creating...
module.identity.aws_iam_role.processing: Creation complete after 0s [id=dataplat-dev-processing]
module.identity.aws_iam_role.audit: Creation complete after 0s [id=dataplat-dev-audit-readonly]
aws_s3_bucket.data_lake: Creation complete after 0s [id=dataplat-dev-lake-000000000000]
module.identity.data.aws_iam_policy_document.processing_permissions: Reading...
module.identity.data.aws_iam_policy_document.audit_permissions: Reading...
aws_s3_bucket_public_access_block.data_lake: Creating...
aws_s3_bucket_versioning.data_lake: Creating...
aws_s3_bucket_server_side_encryption_configuration.data_lake: Creating...
module.identity.data.aws_iam_policy_document.processing_permissions: Read complete after 0s [id=3791610655]
module.identity.data.aws_iam_policy_document.audit_permissions: Read complete after 0s [id=3745648460]
module.identity.aws_iam_role_policy.audit: Creating...
module.identity.aws_iam_role_policy.processing: Creating...
aws_s3_bucket_public_access_block.data_lake: Creation complete after 0s [id=dataplat-dev-lake-000000000000]
aws_s3_bucket_server_side_encryption_configuration.data_lake: Creation complete after 0s [id=dataplat-dev-lake-000000000000]
module.identity.aws_iam_role_policy.audit: Creation complete after 0s [id=dataplat-dev-audit-readonly:dataplat-dev-audit-readonly]
module.identity.aws_iam_role_policy.processing: Creation complete after 0s [id=dataplat-dev-processing:dataplat-dev-processing-s3-prefix]
module.network.aws_vpc.this: Creation complete after 0s [id=vpc-37d46768cb578284d]
module.network.aws_default_security_group.this: Creating...
module.network.aws_route_table.private["us-east-1a"]: Creating...
module.network.aws_route_table.private["us-east-1b"]: Creating...
module.network.aws_subnet.private["us-east-1b"]: Creating...
module.network.aws_subnet.private["us-east-1a"]: Creating...
module.network.aws_subnet.private["us-east-1a"]: Creation complete after 0s [id=subnet-f311bce19f042669f]
module.network.aws_subnet.private["us-east-1b"]: Creation complete after 0s [id=subnet-6e89cfe6d842f5230]
module.network.aws_route_table.private["us-east-1b"]: Creation complete after 1s [id=rtb-c2bc002f4ae8f5d03]
module.network.aws_route_table.private["us-east-1a"]: Creation complete after 1s [id=rtb-132a85be34910dcbe]
module.network.aws_route_table_association.private["us-east-1b"]: Creating...
module.network.aws_route_table_association.private["us-east-1a"]: Creating...
module.network.aws_vpc_endpoint.s3: Creating...
module.network.aws_default_security_group.this: Creation complete after 1s [id=sg-d34cd59c3b747c1b3]
module.network.aws_route_table_association.private["us-east-1a"]: Creation complete after 0s [id=rtbassoc-1403c2a9d126420dc]
module.network.aws_route_table_association.private["us-east-1b"]: Creation complete after 0s [id=rtbassoc-3b4df6c5e435fcbdf]
aws_s3_bucket_versioning.data_lake: Creation complete after 1s [id=dataplat-dev-lake-000000000000]
aws_s3_bucket_lifecycle_configuration.data_lake: Creating...
module.network.aws_vpc_endpoint.s3: Creation complete after 5s [id=vpce-3ba9e07935d96e59d]
aws_s3_bucket_lifecycle_configuration.data_lake: Still creating... [00m10s elapsed]
aws_s3_bucket_lifecycle_configuration.data_lake: Still creating... [00m20s elapsed]
aws_s3_bucket_lifecycle_configuration.data_lake: Still creating... [00m30s elapsed]
aws_s3_bucket_lifecycle_configuration.data_lake: Still creating... [00m40s elapsed]
aws_s3_bucket_lifecycle_configuration.data_lake: Still creating... [00m50s elapsed]
aws_s3_bucket_lifecycle_configuration.data_lake: Creation complete after 55s [id=dataplat-dev-lake-000000000000]

Apply complete! Resources: 18 added, 0 changed, 0 destroyed.

Outputs:

audit_role_arn = "arn:aws:iam::000000000000:role/dataplat-dev-audit-readonly"
data_lake_bucket_arn = "arn:aws:s3:::dataplat-dev-lake-000000000000"
data_lake_bucket_name = "dataplat-dev-lake-000000000000"
private_subnet_ids = [
  "subnet-f311bce19f042669f",
  "subnet-6e89cfe6d842f5230",
]
processing_role_arn = "arn:aws:iam::000000000000:role/dataplat-dev-processing"
s3_vpc_endpoint_id = "vpce-3ba9e07935d96e59d"
vpc_id = "vpc-37d46768cb578284d"
```

## 6. aws ec2 describe-vpc-endpoints

Comando: `aws --endpoint-url=http://localhost:4566 ec2 describe-vpc-endpoints`

> El endpoint de este entorno es el que está en estado `available`, en la VPC del output `vpc_id`, asociado a las dos tablas de rutas privadas. Si aparece otro en estado `deleted`, es de una prueba previa del módulo de red que ya se destruyó: LocalStack lo sigue listando con ese estado.

```json
{
    "VpcEndpoints": [
        {
            "VpcEndpointId": "vpce-0adcb8bd4ce1f0b91",
            "VpcEndpointType": "Gateway",
            "VpcId": "vpc-b1e974fdd2cf95bfb",
            "ServiceName": "com.amazonaws.us-east-1.s3",
            "State": "deleted",
            "PolicyDocument": "{\"Statement\": [{\"Effect\": \"Allow\", \"Principal\": \"*\", \"Action\": \"*\", \"Resource\": \"*\"}]}",
            "RouteTableIds": [
                "rtb-473554dfde7af0c12",
                "rtb-ebc03da28616a0489"
            ],
            "SubnetIds": [],
            "Groups": [],
            "IpAddressType": "ipv4",
            "DnsOptions": {
                "DnsRecordIpType": "ipv4"
            },
            "PrivateDnsEnabled": false,
            "RequesterManaged": false,
            "NetworkInterfaceIds": [],
            "DnsEntries": [],
            "CreationTimestamp": "2026-11-20T15:53:46+00:00",
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "smoke-test-s3-gateway-endpoint"
                }
            ],
            "OwnerId": "000000000000"
        },
        {
            "VpcEndpointId": "vpce-3ba9e07935d96e59d",
            "VpcEndpointType": "Gateway",
            "VpcId": "vpc-37d46768cb578284d",
            "ServiceName": "com.amazonaws.us-east-1.s3",
            "State": "available",
            "PolicyDocument": "{\"Statement\": [{\"Effect\": \"Allow\", \"Principal\": \"*\", \"Action\": \"*\", \"Resource\": \"*\"}]}",
            "RouteTableIds": [
                "rtb-c2bc002f4ae8f5d03",
                "rtb-132a85be34910dcbe"
            ],
            "SubnetIds": [],
            "Groups": [],
            "IpAddressType": "ipv4",
            "DnsOptions": {
                "DnsRecordIpType": "ipv4"
            },
            "PrivateDnsEnabled": false,
            "RequesterManaged": false,
            "NetworkInterfaceIds": [],
            "DnsEntries": [],
            "CreationTimestamp": "2026-11-20T16:04:28+00:00",
            "Tags": [
                {
                    "Key": "Owner",
                    "Value": "data-engineering"
                },
                {
                    "Key": "Name",
                    "Value": "dataplat-dev-s3-gateway-endpoint"
                },
                {
                    "Key": "Project",
                    "Value": "dataplat"
                },
                {
                    "Key": "CostCenter",
                    "Value": "data-platform"
                },
                {
                    "Key": "Environment",
                    "Value": "dev"
                },
                {
                    "Key": "ManagedBy",
                    "Value": "terraform"
                }
            ],
            "OwnerId": "000000000000"
        }
    ]
}
```

## 7. Verificaciones extra de la red

Internet Gateways adjuntos a la VPC (`aws --endpoint-url=http://localhost:4566 ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=<vpc_id>`):

```json
{
    "InternetGateways": []
}
```

Subredes de la VPC (sin IP pública, una por zona):

```text
-----------------------------------------------------------------------------------
|                                 DescribeSubnets                                 |
+------------+---------------+-----------------------+----------------------------+
|     AZ     |     Cidr      |  MapPublicIpOnLaunch  |         SubnetId           |
+------------+---------------+-----------------------+----------------------------+
|  us-east-1a|  10.10.0.0/24 |  False                |  subnet-f311bce19f042669f  |
|  us-east-1b|  10.10.1.0/24 |  False                |  subnet-6e89cfe6d842f5230  |
+------------+---------------+-----------------------+----------------------------+
```

Tablas de rutas de la VPC: solo la ruta `local` y, en las dos privadas, la ruta al prefix list de S3 por el endpoint. Ninguna ruta a `0.0.0.0/0`. La primera es la tabla principal que AWS crea con la VPC y no tiene subredes asociadas.

```json
[
    {
        "Id": "rtb-4d677916659087d02",
        "Rutas": [
            [
                "10.10.0.0/16",
                "local"
            ]
        ]
    },
    {
        "Id": "rtb-c2bc002f4ae8f5d03",
        "Rutas": [
            [
                "10.10.0.0/16",
                "local"
            ],
            [
                "pl-095b088347e66d60c",
                "vpce-3ba9e07935d96e59d"
            ]
        ]
    },
    {
        "Id": "rtb-132a85be34910dcbe",
        "Rutas": [
            [
                "10.10.0.0/16",
                "local"
            ],
            [
                "pl-095b088347e66d60c",
                "vpce-3ba9e07935d96e59d"
            ]
        ]
    }
]
```

## 8. State remoto y segundo plan

State guardado en el bucket del backend (`aws --endpoint-url=http://localhost:4566 s3 ls s3://dataplat-tfstate/environments/dev/`):

```text
2026-11-20 13:05:24      54151 terraform.tfstate
```

Segundo `tflocal plan -detailed-exitcode` después del apply (exit 0 = sin cambios):

```text

Warning: Deprecated Parameter

The parameter "dynamodb_table" is deprecated. Use parameter "use_lockfile"
instead.
data.aws_availability_zones.available: Reading...
data.aws_caller_identity.current: Reading...
module.identity.data.aws_partition.current: Reading...
module.identity.data.aws_caller_identity.current: Reading...
module.network.data.aws_region.current: Reading...
module.network.aws_vpc.this: Refreshing state... [id=vpc-37d46768cb578284d]
module.identity.data.aws_partition.current: Read complete after 0s [id=aws]
module.network.data.aws_region.current: Read complete after 0s [id=us-east-1]
data.aws_caller_identity.current: Read complete after 0s [id=000000000000]
aws_s3_bucket.data_lake: Refreshing state... [id=dataplat-dev-lake-000000000000]
module.identity.data.aws_caller_identity.current: Read complete after 0s [id=000000000000]
module.identity.data.aws_iam_policy_document.audit_trust: Reading...
module.identity.data.aws_iam_policy_document.processing_trust: Reading...
module.identity.data.aws_iam_policy_document.audit_trust: Read complete after 0s [id=1734375019]
module.identity.data.aws_iam_policy_document.processing_trust: Read complete after 0s [id=1655673507]
module.identity.aws_iam_role.audit: Refreshing state... [id=dataplat-dev-audit-readonly]
module.identity.aws_iam_role.processing: Refreshing state... [id=dataplat-dev-processing]
data.aws_availability_zones.available: Read complete after 0s [id=us-east-1]
aws_s3_bucket_versioning.data_lake: Refreshing state... [id=dataplat-dev-lake-000000000000]
aws_s3_bucket_public_access_block.data_lake: Refreshing state... [id=dataplat-dev-lake-000000000000]
aws_s3_bucket_server_side_encryption_configuration.data_lake: Refreshing state... [id=dataplat-dev-lake-000000000000]
module.identity.data.aws_iam_policy_document.processing_permissions: Reading...
module.identity.data.aws_iam_policy_document.processing_permissions: Read complete after 0s [id=3791610655]
module.identity.aws_iam_role_policy.processing: Refreshing state... [id=dataplat-dev-processing:dataplat-dev-processing-s3-prefix]
module.identity.data.aws_iam_policy_document.audit_permissions: Reading...
module.identity.data.aws_iam_policy_document.audit_permissions: Read complete after 0s [id=3745648460]
module.identity.aws_iam_role_policy.audit: Refreshing state... [id=dataplat-dev-audit-readonly:dataplat-dev-audit-readonly]
module.network.aws_route_table.private["us-east-1b"]: Refreshing state... [id=rtb-c2bc002f4ae8f5d03]
module.network.aws_default_security_group.this: Refreshing state... [id=sg-d34cd59c3b747c1b3]
module.network.aws_route_table.private["us-east-1a"]: Refreshing state... [id=rtb-132a85be34910dcbe]
module.network.aws_subnet.private["us-east-1a"]: Refreshing state... [id=subnet-f311bce19f042669f]
module.network.aws_subnet.private["us-east-1b"]: Refreshing state... [id=subnet-6e89cfe6d842f5230]
module.network.aws_route_table_association.private["us-east-1b"]: Refreshing state... [id=rtbassoc-3b4df6c5e435fcbdf]
module.network.aws_route_table_association.private["us-east-1a"]: Refreshing state... [id=rtbassoc-1403c2a9d126420dc]
module.network.aws_vpc_endpoint.s3: Refreshing state... [id=vpce-3ba9e07935d96e59d]
aws_s3_bucket_lifecycle_configuration.data_lake: Refreshing state... [id=dataplat-dev-lake-000000000000]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
exit=0
```
