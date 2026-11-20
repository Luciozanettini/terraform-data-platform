terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  # El módulo declara qué provider necesita, pero NO lo configura: la región,
  # las credenciales y los endpoints los define el entorno que lo llama.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
