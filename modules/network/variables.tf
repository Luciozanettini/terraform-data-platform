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

variable "tags" {
  description = "Tags adicionales para todos los recursos del módulo."
  type        = map(string)
  default     = {}
}
