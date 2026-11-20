variable "name_prefix" {
  description = "Prefijo para los nombres de los roles, con formato <proyecto>-<entorno> (ej: dataplat-dev)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,40}$", var.name_prefix))
    error_message = "name_prefix solo admite minúsculas, números y guiones (3 a 40 caracteres)."
  }
}

variable "data_bucket_arn" {
  description = "ARN del bucket del data lake sobre el que trabaja el rol de procesamiento. Llega como output de otro recurso, nunca escrito a mano."
  type        = string

  validation {
    condition     = can(regex("^arn:[a-z-]+:s3:::[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.data_bucket_arn))
    error_message = "data_bucket_arn debe ser el ARN de un bucket S3 (arn:aws:s3:::nombre-del-bucket), sin rutas ni comodines."
  }
}

variable "processing_prefix" {
  description = "Prefijo (carpeta) del bucket donde el rol de procesamiento puede listar, leer y escribir. Debe terminar en '/' (ej: processed/)."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)*/$", var.processing_prefix))
    error_message = "processing_prefix debe ser una ruta como 'processed/' o 'zona/tabla/': sin '/' inicial, terminada en '/' y sin comodines."
  }
}

variable "processing_trusted_services" {
  description = "Servicios de AWS que pueden asumir el rol de procesamiento. Por defecto Lambda y Managed Service for Apache Flink (kinesisanalytics)."
  type        = list(string)
  default     = ["lambda.amazonaws.com", "kinesisanalytics.amazonaws.com"]

  validation {
    condition     = length(var.processing_trusted_services) > 0 && alltrue([for s in var.processing_trusted_services : can(regex("^[a-z0-9.-]+\\.amazonaws\\.com$", s))])
    error_message = "Cada servicio debe tener la forma <servicio>.amazonaws.com y la lista no puede estar vacía."
  }
}

variable "audit_trusted_principal_arns" {
  description = "ARNs de usuarios o roles que pueden asumir el rol de auditoría. Si queda vacío, se confía en la cuenta actual (la decisión final la toman las políticas IAM de esa cuenta)."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for arn in var.audit_trusted_principal_arns : can(regex("^arn:[a-z-]+:iam::[0-9]{12}:(root|user/.+|role/.+)$", arn))])
    error_message = "Cada principal debe ser un ARN de IAM de cuenta (root), usuario o rol."
  }
}

variable "audit_require_mfa" {
  description = "Si es true, el rol de auditoría solo puede asumirse con una sesión autenticada con MFA."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags adicionales para todos los recursos del módulo."
  type        = map(string)
  default     = {}
}
