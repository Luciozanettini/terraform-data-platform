#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Bootstrap del backend remoto de Terraform en LocalStack.
#
# Crea, con AWS CLI, los dos recursos que Terraform necesita ANTES de poder
# guardar su state de forma remota:
#   1. Bucket S3 para el state (cifrado SSE, versionado, sin acceso público).
#   2. Tabla DynamoDB para el locking (evita dos `apply` simultáneos).
#
# No se crean con Terraform porque serían el lugar donde Terraform guarda su
# propio state (el problema del huevo y la gallina).
#
# Es idempotente: si los recursos ya existen, no falla ni los recrea.
# Uso:  ./scripts/bootstrap-backend.sh
# -----------------------------------------------------------------------------
set -euo pipefail

# Siempre LocalStack: este script nunca debe hablar con AWS real.
ENDPOINT="http://localhost:4566"
REGION="${AWS_REGION:-us-east-1}"
STATE_BUCKET="${STATE_BUCKET:-dataplat-tfstate}"
LOCK_TABLE="${LOCK_TABLE:-dataplat-tf-locks}"

# Credenciales ficticias que LocalStack acepta. Se fuerzan para que nunca se
# usen las credenciales reales que pudiera haber en ~/.aws.
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_DEFAULT_REGION="$REGION"
unset AWS_PROFILE AWS_SESSION_TOKEN || true

aws_local() {
  aws --endpoint-url="$ENDPOINT" "$@"
}

echo "==> Verificando que LocalStack responda en $ENDPOINT"
if ! curl -sf "$ENDPOINT/_localstack/health" > /dev/null; then
  echo "ERROR: LocalStack no responde. Levantalo con: docker compose up -d localstack" >&2
  exit 1
fi

# --- Bucket S3 del state ------------------------------------------------------
if aws_local s3api head-bucket --bucket "$STATE_BUCKET" > /dev/null 2>&1; then
  echo "==> Bucket $STATE_BUCKET ya existe"
else
  echo "==> Creando bucket $STATE_BUCKET"
  # En us-east-1 no se pasa LocationConstraint; en otras regiones sí.
  if [ "$REGION" = "us-east-1" ]; then
    aws_local s3api create-bucket --bucket "$STATE_BUCKET"
  else
    aws_local s3api create-bucket --bucket "$STATE_BUCKET" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi
fi

echo "==> Activando cifrado SSE (AES256) en $STATE_BUCKET"
aws_local s3api put-bucket-encryption --bucket "$STATE_BUCKET" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

echo "==> Activando versionado (permite recuperar un state anterior)"
aws_local s3api put-bucket-versioning --bucket "$STATE_BUCKET" \
  --versioning-configuration Status=Enabled

echo "==> Bloqueando todo acceso público"
aws_local s3api put-public-access-block --bucket "$STATE_BUCKET" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# --- Tabla DynamoDB de locking ------------------------------------------------
if aws_local dynamodb describe-table --table-name "$LOCK_TABLE" > /dev/null 2>&1; then
  echo "==> Tabla $LOCK_TABLE ya existe"
else
  echo "==> Creando tabla $LOCK_TABLE"
  # El backend S3 de Terraform exige una clave de partición llamada LockID (string).
  aws_local dynamodb create-table --table-name "$LOCK_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST > /dev/null
  aws_local dynamodb wait table-exists --table-name "$LOCK_TABLE"
fi

echo "==> Listo. Backend: s3://$STATE_BUCKET  |  lock: $LOCK_TABLE  |  región: $REGION"
