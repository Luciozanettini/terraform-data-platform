# -----------------------------------------------------------------------------
# Módulo network: VPC 100 % privada para la plataforma de datos.
#
# - Sin Internet Gateway ni NAT: nada entra ni sale a internet.
# - Subredes privadas, una por zona de disponibilidad, sin IPs públicas.
# - Acceso a S3 por un Gateway Endpoint, que mantiene el tráfico dentro de
#   la red de AWS sin pasar por internet.
#
# Reutilizable: dev y prod llaman al mismo módulo cambiando solo variables
# (CIDR, cantidad de zonas, prefijo de nombres).
# -----------------------------------------------------------------------------

# Región configurada en el provider del entorno que llama al módulo.
data "aws_region" "current" {}

locals {
  # Mapa zona => índice. Se usa con for_each para que cada subred quede
  # identificada por su zona y no por su posición en la lista.
  az_index = { for idx, az in var.availability_zones : az => idx }
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  # Necesarios para que los servicios dentro de la VPC resuelvan nombres de
  # AWS (incluidos los endpoints) por DNS.
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

# Toma control del security group por defecto de la VPC y lo deja sin reglas.
# Por defecto AWS permite todo el tráfico entre recursos que lo usen; así,
# cualquier recurso que se cree sin security group explícito queda aislado.
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-default-sg-deny-all"
  })
}

resource "aws_subnet" "private" {
  for_each = local.az_index

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc_cidr, var.subnet_newbits, each.value)

  # Ninguna instancia lanzada acá recibe IP pública.
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-${each.key}"
    Tier = "private"
  })
}

# Una tabla de rutas por zona. Solo tiene la ruta "local" (tráfico dentro de
# la VPC) y la ruta a S3 que agrega el Gateway Endpoint. No hay ruta 0.0.0.0/0.
resource "aws_route_table" "private" {
  for_each = local.az_index

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-rt-${each.key}"
    Tier = "private"
  })
}

resource "aws_route_table_association" "private" {
  for_each = local.az_index

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

# Gateway Endpoint de S3: agrega a cada tabla de rutas privada una ruta hacia
# los rangos de IP de S3, sin necesidad de internet ni NAT. No tiene costo.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [for rt in aws_route_table.private : rt.id]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-s3-gateway-endpoint"
  })
}
