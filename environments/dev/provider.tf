terraform {
  # Versión del binario de Terraform: desde 1.5 y nunca una 2.x (con posibles
  # cambios incompatibles).
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # "~> 6.0" = cualquier 6.x, nunca 7.0.
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region

  # Las credenciales NO van acá. El provider las toma de la cadena estándar
  # de AWS (variables de entorno, perfil o rol). Con LocalStack son "test".

  # Tags aplicados automáticamente a todos los recursos que los soporten,
  # incluidos los que crean los módulos.
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
    }
  }
}
