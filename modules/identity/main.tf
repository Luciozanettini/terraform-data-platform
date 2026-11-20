# -----------------------------------------------------------------------------
# Módulo identity: roles IAM de la plataforma con mínimo privilegio.
#
# 1. Rol de procesamiento (Lambda / Flink): solo puede listar, leer y escribir
#    objetos dentro de UN prefijo del bucket del data lake.
# 2. Rol de plano de control (auditoría): solo lectura de la configuración de
#    los recursos de la plataforma, nunca de los datos.
#
# Regla de diseño: ninguna acción ni recurso con "*". Las acciones se listan
# una por una y los recursos se limitan por ARN. El único comodín es el sufijo
# de un prefijo concreto (ej: .../processed/*), que es justamente lo que acota
# el permiso a esa carpeta.
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  # Si no se indican principals para auditoría, se confía en la cuenta actual.
  audit_principals = (
    length(var.audit_trusted_principal_arns) > 0
    ? var.audit_trusted_principal_arns
    : ["arn:${local.partition}:iam::${local.account_id}:root"]
  )
}

# =============================================================================
# Rol de procesamiento
# =============================================================================

# Trust policy: QUIÉN puede asumir el rol. Solo los servicios indicados y solo
# cuando actúan en nombre de esta cuenta (protección "confused deputy").
data "aws_iam_policy_document" "processing_trust" {
  statement {
    sid     = "AllowDataServicesToAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = var.processing_trusted_services
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_iam_role" "processing" {
  name               = "${var.name_prefix}-processing"
  description        = "Rol de procesamiento (Lambda/Flink): lectura y escritura solo en s3://<data-lake>/${var.processing_prefix}"
  assume_role_policy = data.aws_iam_policy_document.processing_trust.json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-processing"
    Role = "processing"
  })
}

# Permission policy: QUÉ puede hacer el rol una vez asumido.
data "aws_iam_policy_document" "processing_permissions" {
  # ListBucket se otorga sobre el bucket, pero la condición s3:prefix hace que
  # solo pueda listar claves que empiecen con el prefijo permitido.
  statement {
    sid       = "ListOnlyProcessingPrefix"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.data_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = [var.processing_prefix, "${var.processing_prefix}*"]
    }
  }

  # Lectura y escritura de objetos, solo dentro del prefijo.
  statement {
    sid       = "ReadWriteObjectsInProcessingPrefix"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${var.data_bucket_arn}/${var.processing_prefix}*"]
  }
}

resource "aws_iam_role_policy" "processing" {
  name   = "${var.name_prefix}-processing-s3-prefix"
  role   = aws_iam_role.processing.id
  policy = data.aws_iam_policy_document.processing_permissions.json
}

# =============================================================================
# Rol de plano de control (auditoría, solo lectura)
# =============================================================================

data "aws_iam_policy_document" "audit_trust" {
  statement {
    sid     = "AllowAuditorsToAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = local.audit_principals
    }

    # Bloque dinámico: la condición de MFA solo se agrega si está activada.
    dynamic "condition" {
      for_each = var.audit_require_mfa ? [1] : []
      content {
        test     = "Bool"
        variable = "aws:MultiFactorAuthPresent"
        values   = ["true"]
      }
    }
  }
}

resource "aws_iam_role" "audit" {
  name                 = "${var.name_prefix}-audit-readonly"
  description          = "Rol de plano de control de solo lectura para auditar la configuración de la plataforma"
  assume_role_policy   = data.aws_iam_policy_document.audit_trust.json
  max_session_duration = 3600

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-audit-readonly"
    Role = "audit"
  })
}

data "aws_iam_policy_document" "audit_permissions" {
  # Configuración del bucket del data lake: cifrado, versionado, bloqueo
  # público, políticas, ciclo de vida y tags. No incluye GetObject: el
  # auditor revisa cómo está configurado el bucket, no lee los datos.
  statement {
    sid    = "ReadDataLakeBucketConfiguration"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetBucketPolicy",
      "s3:GetBucketPolicyStatus",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketVersioning",
      "s3:GetBucketTagging",
      "s3:GetBucketLogging",
      "s3:GetEncryptionConfiguration",
      "s3:GetLifecycleConfiguration",
    ]
    resources = [var.data_bucket_arn]
  }

  # Configuración de los dos roles de la plataforma: trust policy, políticas
  # y tags. Se limita a los ARNs exactos de estos roles.
  statement {
    sid    = "ReadPlatformRolesConfiguration"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListRoleTags",
    ]
    resources = [
      aws_iam_role.processing.arn,
      aws_iam_role.audit.arn,
    ]
  }
}

resource "aws_iam_role_policy" "audit" {
  name   = "${var.name_prefix}-audit-readonly"
  role   = aws_iam_role.audit.id
  policy = data.aws_iam_policy_document.audit_permissions.json
}
