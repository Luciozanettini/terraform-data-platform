output "vpc_id" {
  description = "ID de la VPC privada del entorno."
  value       = module.network.vpc_id
}

output "private_subnet_ids" {
  description = "IDs de las subredes privadas (una por zona de disponibilidad)."
  value       = module.network.private_subnet_ids
}

output "s3_vpc_endpoint_id" {
  description = "ID del S3 Gateway Endpoint asociado a las tablas de rutas privadas."
  value       = module.network.s3_vpc_endpoint_id
}

output "processing_role_arn" {
  description = "ARN del rol de procesamiento (Lambda/Flink)."
  value       = module.identity.processing_role_arn
}

output "audit_role_arn" {
  description = "ARN del rol de plano de control de solo lectura (auditoría)."
  value       = module.identity.audit_role_arn
}

output "data_lake_bucket_name" {
  description = "Nombre del bucket del data lake."
  value       = aws_s3_bucket.data_lake.bucket
}

output "data_lake_bucket_arn" {
  description = "ARN del bucket del data lake, para referenciarlo en políticas sin hardcodearlo."
  value       = aws_s3_bucket.data_lake.arn
}
