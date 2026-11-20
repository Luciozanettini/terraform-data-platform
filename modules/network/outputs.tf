output "vpc_id" {
  description = "ID de la VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "Bloque CIDR de la VPC."
  value       = aws_vpc.this.cidr_block
}

output "private_subnet_ids" {
  description = "IDs de las subredes privadas, en el mismo orden que availability_zones."
  value       = [for az in var.availability_zones : aws_subnet.private[az].id]
}

output "private_route_table_ids" {
  description = "IDs de las tablas de rutas privadas (asociadas al endpoint de S3)."
  value       = [for az in var.availability_zones : aws_route_table.private[az].id]
}

output "s3_vpc_endpoint_id" {
  description = "ID del Gateway Endpoint de S3."
  value       = aws_vpc_endpoint.s3.id
}
