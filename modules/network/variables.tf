variable "name_prefix" {
  description = "Prefijo para los nombres de los recursos, con formato <proyecto>-<entorno> (ej: dataplat-dev)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,40}$", var.name_prefix))
    error_message = "name_prefix solo admite minúsculas, números y guiones (3 a 40 caracteres)."
  }
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC (ej: 10.10.0.0/16). Debe ser un rango privado RFC 1918."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr debe ser un bloque CIDR IPv4 válido, por ejemplo 10.10.0.0/16."
  }
}

variable "availability_zones" {
  description = "Zonas de disponibilidad donde se crea una subred privada por zona. Mínimo 2 para alta disponibilidad."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "Se necesitan al menos 2 zonas de disponibilidad."
  }

  validation {
    condition     = length(distinct(var.availability_zones)) == length(var.availability_zones)
    error_message = "Las zonas de disponibilidad no pueden repetirse."
  }
}

variable "subnet_newbits" {
  description = "Bits que se suman a la máscara de la VPC para cada subred privada (con una VPC /16 y 8 bits, cada subred es /24)."
  type        = number
  default     = 8

  validation {
    condition     = var.subnet_newbits >= 1 && var.subnet_newbits <= 12
    error_message = "subnet_newbits debe estar entre 1 y 12."
  }
}

variable "s3_endpoint_bucket_arns" {
  description = "ARNs de los buckets S3 a los que se permite llegar a través del Gateway Endpoint. Cualquier otro bucket queda bloqueado desde la VPC."
  type        = list(string)

  validation {
    condition     = length(var.s3_endpoint_bucket_arns) > 0
    error_message = "Se necesita al menos un bucket permitido para el endpoint de S3."
  }

  validation {
    condition     = alltrue([for arn in var.s3_endpoint_bucket_arns : can(regex("^arn:[a-z-]+:s3:::[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", arn))])
    error_message = "Cada elemento debe ser el ARN de un bucket (arn:aws:s3:::nombre), sin rutas ni comodines."
  }
}

variable "s3_endpoint_allowed_principal_arns" {
  description = "ARNs de los roles o usuarios IAM que pueden usar el endpoint de S3 (ej: el rol de procesamiento)."
  type        = list(string)

  validation {
    condition     = length(var.s3_endpoint_allowed_principal_arns) > 0
    error_message = "Se necesita al menos un principal permitido para el endpoint de S3."
  }

  validation {
    condition     = alltrue([for arn in var.s3_endpoint_allowed_principal_arns : can(regex("^arn:[a-z-]+:iam::[0-9]{12}:(root|role/.+|user/.+)$", arn))])
    error_message = "Cada principal debe ser un ARN de IAM de cuenta (root), rol o usuario."
  }
}

variable "s3_endpoint_allowed_actions" {
  description = "Acciones de S3 permitidas a través del endpoint. Se listan una por una: no se admiten comodines."
  type        = list(string)
  default     = ["s3:ListBucket", "s3:GetObject", "s3:PutObject"]

  validation {
    condition     = length(var.s3_endpoint_allowed_actions) > 0 && alltrue([for a in var.s3_endpoint_allowed_actions : can(regex("^s3:[A-Za-z]+$", a))])
    error_message = "Cada acción debe ser una acción concreta de S3 (ej: s3:GetObject), sin '*'."
  }
}

variable "tags" {
  description = "Tags adicionales para todos los recursos del módulo."
  type        = map(string)
  default     = {}
}
