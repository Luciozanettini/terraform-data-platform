terraform {
  # Versión del binario de Terraform. Cumple el requisito "> 1.0"
  # y evita que una 2.x (con posibles breaking changes) corra este código.
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # "~> 6.0" = cualquier 6.x, nunca 7.0. Permite fixes y features
      # sin aceptar cambios incompatibles de una versión mayor.
      version = "~> 6.0"
    }
  }

  # En la próxima unidad el state pasa a un backend remoto (S3 + locking).
  # Por ahora queda local y fuera de git (ver .gitignore).
  # backend "s3" {}
}

provider "aws" {
  region = var.region

  # Las credenciales NO van acá. El provider las toma de la cadena estándar
  # de AWS: variables de entorno, ~/.aws/credentials (perfil) o rol de IAM.

  # Tags aplicados automáticamente a TODOS los recursos que soporten tags.
  # Así ningún recurso queda sin dueño ni centro de costos.
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
