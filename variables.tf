variable "region" {
  description = "Región de AWS donde se despliega la plataforma (ej: us-east-1, sa-east-1)."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}(-gov)?-[a-z]+-[0-9]$", var.region))
    error_message = "La región debe tener formato de región de AWS, por ejemplo us-east-1."
  }
}

variable "project_name" {
  description = "Nombre corto del proyecto. Es el prefijo de todos los recursos."
  type        = string

  validation {
    # Minúsculas, números y guiones: compatible con nombres de buckets S3,
    # streams de Kinesis y apps de Flink.
    condition     = can(regex("^[a-z][a-z0-9-]{2,19}$", var.project_name))
    error_message = "project_name: 3 a 20 caracteres, minúsculas, números o guiones, empezando con letra."
  }
}

variable "environment" {
  description = "Entorno de despliegue."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment debe ser dev, staging o prod."
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
  description = "Días que se conservan los objetos en la zona raw antes de expirar."
  type        = number
  default     = 30

  validation {
    condition     = var.raw_data_retention_days >= 1 && var.raw_data_retention_days <= 3650
    error_message = "raw_data_retention_days debe estar entre 1 y 3650."
  }
}
