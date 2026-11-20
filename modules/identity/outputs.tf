output "processing_role_arn" {
  description = "ARN del rol de procesamiento (Lambda/Flink)."
  value       = aws_iam_role.processing.arn
}

output "processing_role_name" {
  description = "Nombre del rol de procesamiento."
  value       = aws_iam_role.processing.name
}

output "audit_role_arn" {
  description = "ARN del rol de plano de control de solo lectura (auditoría)."
  value       = aws_iam_role.audit.arn
}

output "audit_role_name" {
  description = "Nombre del rol de auditoría."
  value       = aws_iam_role.audit.name
}
