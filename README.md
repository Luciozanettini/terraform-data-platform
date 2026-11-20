# terraform-data-platform

Infraestructura base de una plataforma de datos en AWS, escrita en Terraform y probada **100 % en local con LocalStack**. Despliega:

- una **red privada** (VPC sin acceso a internet) con acceso a S3 por un Gateway Endpoint,
- un **data lake** en S3 cifrado y sin acceso público,
- dos **roles IAM de mínimo privilegio**: uno de procesamiento (Lambda/Flink) y otro de auditoría de solo lectura,
- con el **state remoto** en S3 cifrado y locking en DynamoDB.

> Este proyecto nunca habla con AWS real: todos los comandos usan `tflocal` y `aws --endpoint-url=http://localhost:4566`.

---

## Índice

1. [Qué se crea](#qué-se-crea)
2. [Requisitos](#requisitos)
3. [Puesta en marcha paso a paso](#puesta-en-marcha-paso-a-paso)
4. [Cómo verificar lo desplegado](#cómo-verificar-lo-desplegado)
5. [Estructura del repositorio](#estructura-del-repositorio)
6. [Módulos](#módulos)
7. [Decisiones de diseño y seguridad](#decisiones-de-diseño-y-seguridad)
8. [Reutilizar para prod](#reutilizar-para-prod)
9. [Convenciones](#convenciones)
10. [Problemas frecuentes](#problemas-frecuentes)

---

## Qué se crea

```
                         Región us-east-1 (LocalStack)
 ┌──────────────────────────────────────────────────────────────────────┐
 │  VPC 10.10.0.0/16   (sin Internet Gateway, sin NAT)                  │
 │                                                                      │
 │   ┌───────────────────────┐        ┌───────────────────────┐         │
 │   │ subred privada        │        │ subred privada        │         │
 │   │ us-east-1a            │        │ us-east-1b            │         │
 │   │ 10.10.0.0/24          │        │ 10.10.1.0/24          │         │
 │   └──────────┬────────────┘        └──────────┬────────────┘         │
 │      tabla de rutas privada          tabla de rutas privada          │
 │      10.10.0.0/16 → local            10.10.0.0/16 → local            │
 │      prefix list S3 → vpce           prefix list S3 → vpce           │
 │                 └───────────┬───────────────┘                        │
 │                     S3 Gateway Endpoint ─────────────► S3            │
 └──────────────────────────────────────────────────────────────────────┘

 S3:  dataplat-dev-lake-<account_id>   (raw/  y  processed/)
 IAM: dataplat-dev-processing          → List/Get/Put solo en processed/
      dataplat-dev-audit-readonly      → lee configuración, no datos

 Backend (creado antes, con AWS CLI):
      s3://dataplat-tfstate             → state cifrado y versionado
      DynamoDB dataplat-tf-locks        → lock del state
```

| Componente | Recursos | Dónde |
|---|---|---|
| Red | VPC, 2 subredes privadas en AZs distintas, 2 tablas de rutas, S3 Gateway Endpoint, security group por defecto sin reglas | `modules/network` |
| Identidad | Rol de procesamiento + política inline, rol de auditoría + política inline | `modules/identity` |
| Data lake | Bucket S3 con bloqueo público, versionado, cifrado SSE-S3 y expiración de `raw/` | `environments/dev/main.tf` |
| Backend | Bucket S3 del state (SSE, versionado) y tabla DynamoDB de locking | `scripts/bootstrap-backend.sh` |

En total, `tflocal apply` crea **18 recursos**. La salida real está en [PLAN_OUTPUT.md](PLAN_OUTPUT.md).

---

## Requisitos

| Herramienta | Versión probada | Para qué |
|---|---|---|
| Docker Desktop (o Docker Engine + Compose) | 29.x | Correr LocalStack |
| Terraform | `>= 1.5`, `< 2.0` (probado con 1.17.1) | Motor de IaC |
| tflocal (`pip install terraform-local`) | 0.27.0 | Wrapper de Terraform que apunta todo a LocalStack |
| AWS CLI v2 | 2.41.x | Bootstrap del backend y verificaciones |
| Python | >= 3.10 | Requerido por tflocal |
| TFLint (opcional) | 0.65.0 | Linter de HCL |
| Token de LocalStack | — | Variable de entorno `LOCALSTACK_AUTH_TOKEN` |

> **Sobre `tflocal`:** al correrlo muestra un aviso de que está deprecado a favor de `lstk terraform`. Sigue funcionando y es la herramienta usada en este proyecto; el aviso se puede ignorar.

**En Windows**, el script de bootstrap es de bash: correlo desde **Git Bash** (viene con Git for Windows). El resto de los comandos funcionan igual en PowerShell o Git Bash.

---

## Puesta en marcha paso a paso

Todos los comandos se corren desde la raíz del repo salvo que se indique otra cosa.

### 1. Configurar el token de LocalStack (una sola vez)

El token **nunca** se escribe en un archivo del repo. Va solo en la variable de entorno `LOCALSTACK_AUTH_TOKEN`, que `docker compose` lee al levantar el contenedor.

```powershell
# PowerShell: lo pide sin mostrarlo y lo guarda en tu usuario de Windows
$s = Read-Host 'Token' -AsSecureString; [Environment]::SetEnvironmentVariable('LOCALSTACK_AUTH_TOKEN', [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s)), 'User')
```

```bash
# Linux / macOS: agregalo a tu ~/.bashrc o ~/.zshrc
export LOCALSTACK_AUTH_TOKEN="<tu-token>"
```

Abrí una terminal nueva después de configurarlo.

### 2. Credenciales ficticias para LocalStack

LocalStack acepta cualquier credencial; se usan `test` para no tocar nunca las credenciales reales de `~/.aws`.

```bash
# Git Bash / Linux / macOS
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
```

```powershell
# PowerShell
$env:AWS_ACCESS_KEY_ID='test'; $env:AWS_SECRET_ACCESS_KEY='test'; $env:AWS_DEFAULT_REGION='us-east-1'
```

### 3. Levantar LocalStack

```bash
docker compose up -d localstack
```

Esperá a que responda (entre 10 y 30 segundos):

```bash
curl http://localhost:4566/_localstack/health
```

Tiene que mostrar `s3`, `dynamodb`, `ec2`, `iam` y `sts` como `available` o `running`.

> El `docker-compose.yml` también define Postgres y Flink (jobmanager/taskmanager) para etapas siguientes. Para esta infraestructura alcanza con `localstack`; `docker compose up -d` levanta todo.

### 4. Crear el backend remoto (bootstrap)

```bash
./scripts/bootstrap-backend.sh
```

Crea con AWS CLI, siempre contra `http://localhost:4566`:

- el bucket `dataplat-tfstate` con cifrado SSE (AES256), versionado y bloqueo de acceso público,
- la tabla DynamoDB `dataplat-tf-locks` con clave `LockID`.

Es **idempotente**: si ya existen, no falla ni los recrea. Los nombres se pueden cambiar con las variables de entorno `STATE_BUCKET`, `LOCK_TABLE` y `AWS_REGION` (si los cambiás, actualizá también `environments/dev/backend.tf`).

> **¿Por qué no se crean con Terraform?** Porque son el lugar donde Terraform guarda su propio state: tienen que existir antes del primer `init`.

### 5. Inicializar, validar y desplegar el entorno dev

```bash
cd environments/dev

tflocal init        # configura el backend S3 en LocalStack y descarga el provider
tflocal fmt -check -recursive ../..
tflocal validate
tflocal plan        # muestra los 18 recursos a crear
tflocal apply       # escribí "yes" para confirmar
```

Al terminar, `apply` muestra los outputs:

| Output | Qué es |
|---|---|
| `vpc_id` | ID de la VPC |
| `private_subnet_ids` | IDs de las subredes privadas |
| `processing_role_arn` | ARN del rol de procesamiento |
| `audit_role_arn` | ARN del rol de auditoría |
| `s3_vpc_endpoint_id` | ID del Gateway Endpoint de S3 |
| `data_lake_bucket_name` / `data_lake_bucket_arn` | Bucket del data lake |

Para volver a verlos: `tflocal output`.

### 6. Lint (opcional)

Desde la raíz:

```bash
tflint --recursive
```

Usa [.tflint.hcl](.tflint.hcl) con todas las reglas del ruleset de Terraform.

### 7. Apagar

```bash
cd environments/dev && tflocal destroy   # borra los 18 recursos
docker compose down                       # apaga LocalStack (y pierde todo su estado)
```

> LocalStack no persiste datos entre reinicios: después de un `docker compose down` hay que repetir desde el paso 3.

---

## Cómo verificar lo desplegado

```bash
# Endpoint de S3: tipo Gateway, estado available, asociado a las 2 tablas privadas
aws --endpoint-url=http://localhost:4566 ec2 describe-vpc-endpoints

# Ningún Internet Gateway en la VPC (debe devolver una lista vacía)
aws --endpoint-url=http://localhost:4566 ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=$(tflocal output -raw vpc_id)

# Subredes sin IP pública, en AZs distintas
aws --endpoint-url=http://localhost:4566 ec2 describe-subnets --filters Name=vpc-id,Values=$(tflocal output -raw vpc_id) --query "Subnets[].[AvailabilityZone,CidrBlock,MapPublicIpOnLaunch]" --output table

# Políticas de los roles
aws --endpoint-url=http://localhost:4566 iam get-role-policy --role-name dataplat-dev-processing --policy-name dataplat-dev-processing-s3-prefix
aws --endpoint-url=http://localhost:4566 iam get-role-policy --role-name dataplat-dev-audit-readonly --policy-name dataplat-dev-audit-readonly

# Cifrado del bucket del state
aws --endpoint-url=http://localhost:4566 s3api get-bucket-encryption --bucket dataplat-tfstate
```

(Los comandos con `tflocal output` se corren desde `environments/dev`.)

---

## Estructura del repositorio

```
.
├── docker-compose.yml          # LocalStack + Postgres + Flink
├── scripts/
│   └── bootstrap-backend.sh    # Crea el bucket del state y la tabla de lock (AWS CLI)
├── modules/
│   ├── network/                # VPC privada reutilizable
│   │   ├── versions.tf
│   │   ├── variables.tf
│   │   ├── main.tf
│   │   └── outputs.tf
│   └── identity/               # Roles IAM de mínimo privilegio
│       ├── versions.tf
│       ├── variables.tf
│       ├── main.tf
│       └── outputs.tf
├── environments/
│   └── dev/                    # Root module del entorno dev
│       ├── backend.tf          # Backend S3 + DynamoDB
│       ├── provider.tf         # Versiones, provider AWS y default_tags
│       ├── variables.tf        # environment, region, vpc_cidr, etc.
│       ├── main.tf             # Llama a los módulos y crea el data lake
│       ├── outputs.tf          # vpc_id, private_subnet_ids, ARNs de roles
│       ├── terraform.tfvars    # Valores de dev (sin secretos)
│       └── .terraform.lock.hcl # Versiones exactas del provider
├── .tflint.hcl
├── PLAN_OUTPUT.md              # Salidas reales de plan, apply y verificaciones
└── README.md
```

Terraform lee todos los `.tf` de una carpeta como si fueran uno: separarlos es para las personas. Cada archivo responde una pregunta (¿qué versiones? ¿qué se configura? ¿qué se crea? ¿qué se expone?).

---

## Módulos

### `modules/network`

| Variable | Tipo | Default | Descripción |
|---|---|---|---|
| `name_prefix` | `string` | — | Prefijo de nombres (`dataplat-dev`) |
| `vpc_cidr` | `string` | — | CIDR de la VPC |
| `availability_zones` | `list(string)` | — | Una subred privada por zona; mínimo 2, sin repetir |
| `subnet_newbits` | `number` | `8` | Bits extra para cada subred (`/16` + 8 = `/24`) |
| `tags` | `map(string)` | `{}` | Tags adicionales |

Outputs: `vpc_id`, `vpc_cidr_block`, `private_subnet_ids`, `private_route_table_ids`, `s3_vpc_endpoint_id`.

### `modules/identity`

| Variable | Tipo | Default | Descripción |
|---|---|---|---|
| `name_prefix` | `string` | — | Prefijo de nombres |
| `data_bucket_arn` | `string` | — | ARN del bucket del data lake (llega como output, nunca escrito a mano) |
| `processing_prefix` | `string` | — | Carpeta del bucket habilitada para el rol de procesamiento (`processed/`) |
| `processing_trusted_services` | `list(string)` | Lambda y Managed Flink | Servicios que pueden asumir el rol de procesamiento |
| `audit_trusted_principal_arns` | `list(string)` | `[]` (la cuenta actual) | Quién puede asumir el rol de auditoría |
| `audit_require_mfa` | `bool` | `true` | Exige MFA para asumir el rol de auditoría |
| `tags` | `map(string)` | `{}` | Tags adicionales |

Outputs: `processing_role_arn`, `processing_role_name`, `audit_role_arn`, `audit_role_name`.

---

## Decisiones de diseño y seguridad

### Red cerrada

- **Sin Internet Gateway, sin NAT, sin rutas a `0.0.0.0/0`.** Nada dentro de la VPC puede salir a internet ni ser alcanzado desde afuera.
- **`map_public_ip_on_launch = false`** en todas las subredes.
- **S3 por Gateway Endpoint:** agrega a cada tabla de rutas privada una ruta al *prefix list* de S3, así el tráfico a S3 viaja por la red interna de AWS. No tiene costo.
- **Security group por defecto sin reglas:** por defecto AWS permite todo el tráfico entre recursos que lo usan; vaciarlo hace que cualquier recurso creado sin security group propio quede aislado.
- **Subredes con `for_each` por zona:** agregar una zona no destruye ni recrea las existentes.

### IAM sin comodines

- **Ninguna acción ni recurso `"*"`.** No hay `Action: "*"`, `s3:*` ni `Resource: "*"`; las acciones se listan una por una y los recursos se limitan por ARN.
- **Rol de procesamiento:** `s3:ListBucket` sobre el bucket con la condición `s3:prefix` = `processed/`, y `s3:GetObject` / `s3:PutObject` sobre `arn:aws:s3:::<bucket>/processed/*`. Ese `*` final es el sufijo del prefijo: es lo que **restringe** el permiso a esa carpeta, no un comodín amplio. No tiene `DeleteObject` ni acceso a `raw/`.
- **Trust del rol de procesamiento** limitado a `lambda.amazonaws.com` y `kinesisanalytics.amazonaws.com` (Managed Service for Apache Flink), y solo cuando actúan para esta cuenta (`aws:SourceAccount`, protección contra *confused deputy*).
- **Rol de auditoría (plano de control):** lee la configuración del bucket del data lake (cifrado, versionado, bloqueo público, políticas, lifecycle, tags) y de los dos roles (`iam:GetRole`, `GetRolePolicy`, etc.). **No** tiene `s3:GetObject`: audita cómo está configurado, no lee datos. Se asume solo con MFA.
- **Por qué el rol de auditoría no incluye `ec2:Describe*`:** esas acciones no admiten permisos a nivel de recurso y AWS exige `Resource: "*"`. Para cumplir la regla de cero comodines se dejaron afuera; si se quisiera auditar la red, habría que aceptar esa excepción documentada.

### State y secretos

- **State remoto** en S3 cifrado (SSE AES256) y versionado, con lock en DynamoDB para que dos `apply` simultáneos no lo corrompan.
  - Terraform 1.11+ marca `dynamodb_table` como deprecado y recomienda `use_lockfile` (lock nativo en S3). Se mantiene DynamoDB porque lo pide la consigna; migrar es cambiar una línea en `backend.tf`.
- **Nada sensible en git:** `.gitignore` excluye `.terraform/`, `*.tfstate*`, `checkpoints/`, `.env` y `*.secret.tfvars`.
- **Token de LocalStack** solo como variable de entorno.
- **Sin IDs ni ARNs hardcodeados:** el bucket se pasa al módulo de identidad por output; el account ID, la partición, la región y las zonas salen de *data sources*.

---

## Reutilizar para prod

Los módulos no tienen nada atado a dev. Para un entorno nuevo:

1. Copiar `environments/dev` a `environments/prod`.
2. En `backend.tf`, cambiar `key` a `environments/prod/terraform.tfstate`.
3. En `terraform.tfvars`, cambiar `environment = "prod"`, un `vpc_cidr` que no se solape (ej. `10.20.0.0/16`) y, si se quiere más disponibilidad, `az_count = 3`.

En prod, `force_destroy` del bucket queda desactivado automáticamente (`environment != "prod"`).

---

## Convenciones

**Nombres:** `<proyecto>-<entorno>-<componente>[-<sufijo>]`, por ejemplo `dataplat-dev-processing` o `dataplat-dev-lake-000000000000`. Solo minúsculas, números y guiones (válido para S3, IAM y Flink). El prefijo se calcula una sola vez en `local.name_prefix`.

**Tags:** el bloque `default_tags` del provider agrega a todos los recursos, incluidos los de los módulos:

| Tag | Origen |
|---|---|
| `Project` | `var.project_name` |
| `Environment` | `var.environment` |
| `Owner` | `var.owner` |
| `CostCenter` | `var.cost_center` |
| `ManagedBy` | `terraform` |

---

## Problemas frecuentes

| Síntoma | Causa y solución |
|---|---|
| `LocalStack no responde` al correr el bootstrap | El contenedor no está arriba o todavía arranca. `docker compose ps` y esperar al health check. |
| LocalStack arranca pero falla con error de licencia | Falta `LOCALSTACK_AUTH_TOKEN` en la terminal desde la que se corrió `docker compose`. Configurarlo (paso 1) y abrir una terminal nueva. |
| `tflocal init` falla con `NoSuchBucket` | No se corrió el bootstrap, o LocalStack se reinició y perdió los datos. Repetir el paso 4. |
| `Error acquiring the state lock` | Quedó un lock de un `apply` cortado. `tflocal force-unlock <LOCK_ID>` con el ID que muestra el error. |
| `bash: ./scripts/bootstrap-backend.sh: /bin/bash^M` | El script tiene fin de línea CRLF. El repo lo fuerza a LF con `.gitattributes`; volver a clonar o `git checkout -- scripts/`. |
| `tflocal: command not found` | El directorio de scripts de Python no está en el `PATH`. Reinstalar con `pip install terraform-local` y abrir una terminal nueva. |
