# -----------------------------------------------------------------------------
# Entorno dev: arma la plataforma llamando a los módulos reutilizables.
# Los recursos se conectan entre sí por outputs (nunca IDs ni ARNs escritos
# a mano).
# -----------------------------------------------------------------------------

# Cuenta actual: se usa para que el nombre del bucket sea único a nivel global
# sin hardcodear el ID de cuenta.
data "aws_caller_identity" "current" {}

# Zonas de disponibilidad de la región: se toman las primeras var.az_count.
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Convención de nombres: <proyecto>-<entorno>-<componente>
  name_prefix        = "${var.project_name}-${var.environment}"
  availability_zones = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

# -----------------------------------------------------------------------------
# Red privada
# -----------------------------------------------------------------------------

module "network" {
  source = "../../modules/network"

  name_prefix        = local.name_prefix
  vpc_cidr           = var.vpc_cidr
  availability_zones = local.availability_zones

  # Desde la VPC solo se llega al data lake, y solo con el rol de
  # procesamiento (que es el que corre adentro: Lambda/Flink).
  s3_endpoint_bucket_arns            = [aws_s3_bucket.data_lake.arn]
  s3_endpoint_allowed_principal_arns = [module.identity.processing_role_arn]
}

# -----------------------------------------------------------------------------
# Data lake (S3)
# Prefijos: raw/ (datos crudos, con expiración) y processed/ (salida de los
# jobs de procesamiento).
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "data_lake" {
  # Los nombres de bucket son globales en todo AWS: el sufijo con el
  # account ID evita choques con buckets de otras cuentas.
  bucket = "${local.name_prefix}-lake-${data.aws_caller_identity.current.account_id}"

  # Solo fuera de prod se permite borrar el bucket con datos adentro.
  force_destroy = var.environment != "prod"

  tags = {
    Name = "${local.name_prefix}-lake"
  }
}

# Bloquea cualquier acceso público al bucket, aunque alguien agregue
# después una ACL o una policy pública por error.
resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versionado: permite recuperar objetos sobrescritos o borrados.
resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Cifrado en reposo con claves administradas por S3 (SSE-S3).
resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Expiración de los datos crudos (solo raw/) para controlar costos.
resource "aws_s3_bucket_lifecycle_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    id     = "expire-raw-data"
    status = "Enabled"

    filter {
      prefix = "raw/"
    }

    expiration {
      days = var.raw_data_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.raw_data_retention_days
    }
  }

  # El lifecycle depende del versionado para aplicar a versiones no actuales.
  depends_on = [aws_s3_bucket_versioning.data_lake]
}

# -----------------------------------------------------------------------------
# Identidad: roles de procesamiento y de auditoría
# -----------------------------------------------------------------------------

module "identity" {
  source = "../../modules/identity"

  name_prefix       = local.name_prefix
  data_bucket_arn   = aws_s3_bucket.data_lake.arn
  processing_prefix = var.processing_prefix
}
