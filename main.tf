# -----------------------------------------------------------------------------
# Datos y convenciones comunes
# -----------------------------------------------------------------------------

# Cuenta de AWS actual. Se usa para que el nombre del bucket sea único a nivel
# global sin hardcodear el ID de cuenta.
data "aws_caller_identity" "current" {}

locals {
  # Convención de nombres: <proyecto>-<entorno>-<componente>
  # Ej: dataplat-dev-raw, dataplat-prod-telemetry-stream
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# Zona raw del data lake (S3)
# Acá aterrizan los datos crudos que luego van a llegar desde Kinesis/Flink.
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "raw" {
  # Los nombres de bucket son globales en todo AWS: el sufijo con el
  # account ID evita choques con buckets de otras cuentas.
  bucket = "${local.name_prefix}-raw-${data.aws_caller_identity.current.account_id}"

  # Solo en entornos no productivos se permite borrar el bucket con datos
  # adentro (útil para entornos efímeros y `terraform destroy`).
  force_destroy = var.environment != "prod"

  # Para el storage productivo conviene además:
  # lifecycle {
  #   prevent_destroy = true
  # }
  # No se puede parametrizar por entorno (lifecycle no acepta variables),
  # por eso se activa cuando este código se separe por entorno.

  tags = {
    DataZone = "raw"
  }
}

# Bloquea cualquier acceso público al bucket, aunque alguien agregue
# después una ACL o una policy pública por error.
resource "aws_s3_bucket_public_access_block" "raw" {
  bucket = aws_s3_bucket.raw.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versionado: permite recuperar objetos sobrescritos o borrados.
resource "aws_s3_bucket_versioning" "raw" {
  bucket = aws_s3_bucket.raw.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Cifrado en reposo con claves administradas por S3 (SSE-S3).
resource "aws_s3_bucket_server_side_encryption_configuration" "raw" {
  bucket = aws_s3_bucket.raw.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Expiración de datos crudos para controlar costos de almacenamiento.
resource "aws_s3_bucket_lifecycle_configuration" "raw" {
  bucket = aws_s3_bucket.raw.id

  rule {
    id     = "expire-raw-data"
    status = "Enabled"

    filter {}

    expiration {
      days = var.raw_data_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.raw_data_retention_days
    }
  }

  # El lifecycle depende del versionado para aplicar a versiones no actuales.
  depends_on = [aws_s3_bucket_versioning.raw]
}

# -----------------------------------------------------------------------------
# Próximas fases (fuera del alcance de esta entrega)
# -----------------------------------------------------------------------------
# - aws_kinesis_stream: ingesta de eventos (shard_count por entorno).
# - aws_kinesisanalyticsv2_application: job de Apache Flink.
# - IAM roles con mínimo privilegio para que Flink lea de Kinesis y escriba en S3.
