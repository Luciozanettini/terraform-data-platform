output "raw_bucket_name" {
  description = "Nombre del bucket de la zona raw. Lo consumen los jobs de ingesta y el orquestador."
  value       = aws_s3_bucket.raw.bucket
}

output "raw_bucket_arn" {
  description = "ARN del bucket raw, para referenciarlo en políticas de IAM sin hardcodearlo."
  value       = aws_s3_bucket.raw.arn
}

output "name_prefix" {
  description = "Prefijo de nombres aplicado a los recursos de este entorno."
  value       = local.name_prefix
}
