# -----------------------------------------------------------------------------
# Backend remoto: el state de este entorno vive en S3 y se bloquea con DynamoDB.
#
# El bucket y la tabla se crean ANTES con scripts/bootstrap-backend.sh (no con
# Terraform, porque son el lugar donde Terraform guarda su propio state).
#
# Terraform no permite variables dentro del bloque backend: los nombres van
# fijos acá. Cada entorno usa una key distinta dentro del mismo bucket.
#
# Con `tflocal`, los endpoints de S3 y DynamoDB se redirigen solos a LocalStack.
# -----------------------------------------------------------------------------

terraform {
  backend "s3" {
    bucket         = "dataplat-tfstate"
    key            = "environments/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "dataplat-tf-locks"
  }
}
