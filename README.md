# terraform-data-platform

Esqueleto de un proyecto de Terraform para una plataforma de datos en AWS que, en próximas etapas, va a incluir ingesta con **Kinesis** y procesamiento con **Apache Flink**. Por ahora despliega la zona *raw* del data lake en S3 con las protecciones básicas: bloqueo de acceso público, versionado, cifrado y expiración de datos.

## Requisitos

| Herramienta | Versión |
|---|---|
| Terraform | `>= 1.5.0, < 2.0.0` |
| Provider AWS (`hashicorp/aws`) | `~> 6.0` |
| Credenciales de AWS | Perfil en `~/.aws/credentials`, variables de entorno o rol de IAM |

Las credenciales **nunca** se escriben en el código: el provider las toma de la cadena estándar de AWS.

## Cómo inicializar y usar el proyecto

```bash
# 1. Descargar el provider de AWS y preparar el directorio de trabajo
terraform init

# 2. Formatear y validar la sintaxis (no necesita credenciales)
terraform fmt -check
terraform validate

# 3. Ver qué cambios se harían (usa terraform.tfvars automáticamente)
terraform plan

# 4. Aplicar los cambios después de revisar el plan
terraform apply

# 5. Borrar todo lo creado (entornos de prueba)
terraform destroy
```

Para otro entorno, crear un archivo de variables y pasarlo explícitamente:

```bash
terraform plan -var-file=prod.tfvars
```

> En esta etapa el state es **local** y está excluido de git. En la próxima unidad se mueve a un backend remoto en S3 con locking.

## Estructura del proyecto

```
.
├── provider.tf        # Versión de Terraform, providers y tags por defecto
├── variables.tf       # Entradas del proyecto, con tipo, descripción y validaciones
├── main.tf            # Recursos (bucket S3 de la zona raw)
├── outputs.tf         # Valores que exporta el proyecto
├── terraform.tfvars   # Valores concretos del entorno dev
├── .gitignore         # Excluye state, .terraform/ y archivos sensibles
└── README.md
```

### ¿Por qué separar en varios archivos y no un único `main.tf`?

Terraform lee **todos** los `.tf` de la carpeta como si fueran uno solo, así que separarlos no cambia el comportamiento: es una decisión para las personas que leen y mantienen el código.

- **Cada archivo responde una pregunta.** ¿Qué versiones uso? → `provider.tf`. ¿Qué puedo configurar? → `variables.tf`. ¿Qué se crea? → `main.tf`. ¿Qué expone? → `outputs.tf`. Quien llega al proyecto encuentra todo sin leer cientos de líneas.
- **La interfaz queda separada de la implementación.** `variables.tf` y `outputs.tf` son el "contrato" del proyecto; cuando se convierta en módulo, ese contrato ya está definido.
- **Revisiones más claras.** Un cambio de versión del provider o un nuevo output aparece en un diff chico y aislado, no mezclado con recursos.
- **El código se separa de los valores.** El mismo código sirve para `dev`, `staging` y `prod`; solo cambia el `.tfvars`.

Es la convención estándar de la comunidad (y la que usa HashiCorp en sus módulos), lo que reduce la curva de entrada para otros ingenieros.

## Convención de nombres

Todos los recursos siguen el patrón:

```
<proyecto>-<entorno>-<componente>[-<sufijo>]
```

| Parte | Regla | Ejemplo |
|---|---|---|
| `proyecto` | 3 a 20 caracteres, minúsculas, números y guiones | `dataplat` |
| `entorno` | `dev`, `staging` o `prod` | `dev` |
| `componente` | Qué es el recurso | `raw`, `telemetry-stream` |
| `sufijo` | Solo si el nombre debe ser único globalmente (buckets S3): ID de la cuenta | `123456789012` |

Ejemplos: `dataplat-dev-raw-123456789012`, `dataplat-prod-telemetry-stream`.

**Por qué así:** solo minúsculas y guiones porque es el subconjunto válido para S3, Kinesis y Flink a la vez; el entorno en el nombre evita confundir recursos de prod y dev en la consola; y el prefijo se calcula una sola vez en `local.name_prefix` para que nadie lo escriba a mano. Las reglas se validan en `variables.tf`: un nombre inválido falla en `plan`, antes de llegar a AWS.

## Tags obligatorios

El bloque `default_tags` del provider agrega a **todos** los recursos:

| Tag | Origen |
|---|---|
| `Project` | `var.project_name` |
| `Environment` | `var.environment` |
| `Owner` | `var.owner` |
| `CostCenter` | `var.cost_center` |
| `ManagedBy` | `terraform` (fijo) |

`ManagedBy = terraform` avisa a cualquiera que entre a la consola que ese recurso no se toca a mano (evita el *drift*).

## Decisiones de diseño y seguridad

- **State fuera de git:** `*.tfstate` puede contener secretos en texto plano y genera conflictos entre personas.
- **`terraform.tfvars` sí se versiona:** solo tiene valores no sensibles (región, nombres). Los secretos irían en `*.secret.tfvars` (ignorado) o en variables de entorno `TF_VAR_*`.
- **`.terraform.lock.hcl` sí se versiona** (cuando se genere con `init`): fija las versiones exactas de los providers para todo el equipo.
- **`force_destroy` solo fuera de prod:** en `dev` se puede destruir el bucket con datos; en `prod`, Terraform falla si el bucket no está vacío.
- **Sin ARNs ni account IDs hardcodeados:** se obtienen con `data.aws_caller_identity` y referencias entre recursos.

## Próximos pasos

- Backend remoto en S3 con locking para el state.
- Stream de Kinesis con `shard_count` por entorno.
- Aplicación de Flink (`aws_kinesisanalyticsv2_application`) con rol de IAM de mínimo privilegio.
- Separar el state por dominio (red, IAM, streaming, analítica) para reducir el *blast radius*.
