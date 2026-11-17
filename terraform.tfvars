# Valores del entorno de desarrollo.
# Este archivo NO debe contener secretos: se versiona en git.
# Para otro entorno: copiar a staging.tfvars / prod.tfvars y usar
#   terraform plan -var-file=prod.tfvars

region                  = "us-east-1"
project_name            = "dataplat"
environment             = "dev"
owner                   = "data-engineering"
cost_center             = "data-platform"
raw_data_retention_days = 30
