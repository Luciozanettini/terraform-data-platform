variable "region" {
  description = "Región de AWS donde se despliega la plataforma (ej: us-east-1, sa-east-1)."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}(-gov)?-[a-z]+-[0-9]$", var.region))
    error_message = "La región debe tener formato de región de AWS, por ejemplo us-east-1."
  }
}

variable "environment" {
  description = "Entorno de despliegue (dev, staging o prod). Forma parte del nombre de todos los recursos."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment debe ser dev, staging o prod."
  }
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC de este entorno. Cada entorno usa un rango distinto para poder conectarlos sin solaparse."
  type        = string
  default     = "10.10.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr debe ser un bloque CIDR IPv4 válido, por ejemplo 10.10.0.0/16."
  }
}

variable "az_count" {
  description = "Cantidad de zonas de disponibilidad (y de subredes privadas) a usar. Mínimo 2."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 6
    error_message = "az_count debe estar entre 2 y 6."
  }
}

variable "project_name" {
  description = "Nombre corto del proyecto. Es el prefijo de todos los recursos."
  type        = string

  validation {
    # Minúsculas, números y guiones: compatible con nombres de buckets S3.
    condition     = can(regex("^[a-z][a-z0-9-]{2,19}$", var.project_name))
    error_message = "project_name: 3 a 20 caracteres, minúsculas, números o guiones, empezando con letra."
  }
}

variable "owner" {
  description = "Equipo o persona responsable de los recursos (se usa como tag Owner)."
  type        = string
}

variable "cost_center" {
  description = "Centro de costos para imputar el gasto de AWS (tag CostCenter)."
  type        = string
}

variable "raw_data_retention_days" {
  description = "Días que se conservan los objetos del prefijo raw/ del data lake antes de expirar."
  type        = number
  default     = 30

  validation {
    condition     = var.raw_data_retention_days >= 1 && var.raw_data_retention_days <= 3650
    error_message = "raw_data_retention_days debe estar entre 1 y 3650."
  }
}

variable "processing_prefix" {
  description = "Prefijo del data lake donde el rol de procesamiento puede listar, leer y escribir (ej: processed/)."
  type        = string
  default     = "processed/"
}
