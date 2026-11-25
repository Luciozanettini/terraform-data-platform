# terraform-data-platform

Infraestructura base de una plataforma de datos en AWS, escrita en Terraform y probada **100 % en local con LocalStack**. Despliega:

- una **red privada** (VPC sin acceso a internet) con acceso a S3 por un Gateway Endpoint,
- un **data lake** en S3 cifrado y sin acceso público,
- dos **roles IAM de mínimo privilegio**: uno de procesamiento (Lambda/Flink) y otro de auditoría de solo lectura,
- con el **state remoto** en S3 cifrado y locking en DynamoDB.

> Este proyecto nunca habla con AWS real: todos los comandos usan `tflocal` y `aws --endpoint-url=http://localhost:4566`.

**Para revisar la entrega:**
- [Puesta en marcha paso a paso](#puesta-en-marcha-paso-a-paso): cómo levantar todo.
- [Cómo verificar cada criterio de la consigna](#cómo-verificar-cada-criterio-de-la-consigna): una tabla que lleva de cada criterio al archivo donde está y al comando que lo comprueba.
- [PLAN_OUTPUT.md](PLAN_OUTPUT.md): la salida real de todos esos comandos.

---

## Índice

1. [Qué se crea](#qué-se-crea)
2. [Requisitos](#requisitos)
3. [Puesta en marcha paso a paso](#puesta-en-marcha-paso-a-paso)
4. [Cómo verificar cada criterio de la consigna](#cómo-verificar-cada-criterio-de-la-consigna)
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
| Red | VPC, 2 subredes privadas en AZs distintas, 2 tablas de rutas, S3 Gateway Endpoint con policy restrictiva, security group por defecto sin reglas | `modules/network` |
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

## Cómo verificar cada criterio de la consigna

### Resumen: criterio → dónde está → cómo se verifica

| # | Criterio | Dónde está | Verificación |
|---|---|---|---|
| 1 | Estructura `modules/network`, `modules/identity`, `environments/dev`, `README.md` | [modules/](modules/), [environments/dev/](environments/dev/) | [C1](#c1-estructura-del-repositorio) |
| 2 | `docker-compose.yml` en la raíz con el contenido provisto | [docker-compose.yml](docker-compose.yml) | [C2](#c2-docker-composeyml) |
| 3 | Backend remoto: S3 con SSE + DynamoDB para locking, creados con AWS CLI | [scripts/bootstrap-backend.sh](scripts/bootstrap-backend.sh), [environments/dev/backend.tf](environments/dev/backend.tf) | [C3](#c3-backend-remoto-s3--dynamodb) |
| 4 | `variables.tf` con tipo y descripción: entorno, región y CIDR de la VPC | [environments/dev/variables.tf](environments/dev/variables.tf) | [C4](#c4-variables-con-tipo-y-descripción) |
| 5 | VPC con ≥ 2 subredes privadas en AZs distintas, sin IGW ni IPs públicas | [modules/network/main.tf](modules/network/main.tf) | [C5](#c5-red-privada) |
| 6 | S3 Gateway Endpoint asociado a las tablas de rutas privadas | [modules/network/main.tf](modules/network/main.tf) | [C6](#c6-s3-gateway-endpoint) |
| 7 | Rol de procesamiento: solo `s3:ListBucket`, `s3:GetObject` y `s3:PutObject` sobre un prefijo | [modules/identity/main.tf](modules/identity/main.tf) | [C7](#c7-roles-iam) |
| 8 | Rol de plano de control de solo lectura para auditoría | [modules/identity/main.tf](modules/identity/main.tf) | [C7](#c7-roles-iam) |
| 9 | Ningún permiso con `"*"` | [modules/identity/main.tf](modules/identity/main.tf) | [C8](#c8-ningún-permiso-con-) |
| 10 | Outputs `vpc_id`, `private_subnet_ids` y ARNs de los roles | [environments/dev/outputs.tf](environments/dev/outputs.tf) | [C9](#c9-outputs) |
| 11 | `tflocal validate`, `tflint`, `tflocal plan`, `tflocal apply` | — | [C10](#c10-validación-validate-tflint-plan-apply) |
| 12 | `PLAN_OUTPUT.md` con plan, apply y `describe-vpc-endpoints` | [PLAN_OUTPUT.md](PLAN_OUTPUT.md) | [C11](#c11-plan_outputmd) |
| 13 | Repo sin `.terraform/`, `*.tfstate*`, `checkpoints/` ni secretos | [.gitignore](.gitignore) | [C12](#c12-nada-sensible-en-el-repo) |
| 14 | Módulo de red reutilizable para prod | [modules/network/](modules/network/) | [Reutilizar para prod](#reutilizar-para-prod) |

### Antes de verificar

Los comandos son de **bash** (en Windows, Git Bash). Se asume que ya se hicieron los pasos 1 a 5 de la [puesta en marcha](#puesta-en-marcha-paso-a-paso): LocalStack arriba, bootstrap corrido y `tflocal apply` hecho. Todos los comandos de AWS CLI apuntan a LocalStack con `--endpoint-url=http://localhost:4566`.

```bash
cd environments/dev
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
EP=http://localhost:4566
VPC=$(tflocal output -raw vpc_id)
```

Desde ahí, todos los comandos se corren en `environments/dev`.

### C1. Estructura del repositorio

```bash
ls ../../modules/network ../../modules/identity .
```

**Esperado:**
- `main.tf`, `variables.tf`, `outputs.tf` y `versions.tf` en cada módulo;
- `backend.tf`, `main.tf` (llama a los dos módulos con `source = "../../modules/..."`), `provider.tf`, `variables.tf`, `outputs.tf` y `terraform.tfvars` en `environments/dev`.

### C2. docker-compose.yml

```bash
docker compose -f ../../docker-compose.yml config --services
```

**Esperado:** `jobmanager`, `localstack`, `postgres` y `taskmanager`. El archivo es la copia exacta del provisto, sin cambios.

### C3. Backend remoto (S3 + DynamoDB)

El bucket y la tabla se crean con AWS CLI en [scripts/bootstrap-backend.sh](scripts/bootstrap-backend.sh), y [backend.tf](environments/dev/backend.tf) los usa.

```bash
aws --endpoint-url=$EP s3api get-bucket-encryption --bucket dataplat-tfstate
aws --endpoint-url=$EP s3api get-bucket-versioning --bucket dataplat-tfstate
aws --endpoint-url=$EP dynamodb describe-table --table-name dataplat-tf-locks --query "Table.KeySchema"
aws --endpoint-url=$EP s3 ls s3://dataplat-tfstate/environments/dev/
```

**Esperado:**
- `SSEAlgorithm: AES256`;
- `Status: Enabled`;
- clave `LockID` de tipo `HASH`;
- el archivo `terraform.tfstate` dentro del bucket. El state no queda en la máquina local.

### C4. Variables con tipo y descripción

```bash
grep -A3 -E 'variable "(environment|region|vpc_cidr)"' variables.tf
```

**Esperado:** cada una con `description` y `type = string`. Las tres tienen además un bloque `validation`: región con formato de AWS, entorno `dev`/`staging`/`prod` y CIDR IPv4 válido.

Todas las variables del repo (las del entorno y las de los módulos) tienen tipo y descripción. Lo controla TFLint con las reglas `terraform_typed_variables` y `terraform_documented_variables` (ver [C10](#c10-validación-validate-tflint-plan-apply)).

### C5. Red privada

```bash
# Subredes: 2, en AZs distintas, sin IP pública
aws --endpoint-url=$EP ec2 describe-subnets --filters Name=vpc-id,Values=$VPC \
  --query "Subnets[].[AvailabilityZone,CidrBlock,MapPublicIpOnLaunch]" --output table

# Internet Gateways adjuntos a la VPC
aws --endpoint-url=$EP ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=$VPC

# Rutas a internet (0.0.0.0/0) en las tablas de la VPC
aws --endpoint-url=$EP ec2 describe-route-tables --filters Name=vpc-id,Values=$VPC \
  --query "RouteTables[].Routes[?DestinationCidrBlock=='0.0.0.0/0'][]"
```

**Esperado:**
- dos filas, `us-east-1a` y `us-east-1b`, con `False` en la IP pública;
- `"InternetGateways": []`;
- `[]`: ninguna ruta a internet.

### C6. S3 Gateway Endpoint

```bash
aws --endpoint-url=$EP ec2 describe-vpc-endpoints \
  --query "VpcEndpoints[].[VpcEndpointId,VpcEndpointType,ServiceName,State,RouteTableIds]"
aws --endpoint-url=$EP ec2 describe-route-tables --filters Name=vpc-id,Values=$VPC \
  --query "RouteTables[].[RouteTableId,Associations[].SubnetId,Routes[].GatewayId]"
```

**Esperado:**
- El endpoint es `Gateway`, de `com.amazonaws.us-east-1.s3`, en estado `available`, con dos IDs de tabla de rutas.
- Esas dos tablas son las que tienen asociada una subred privada cada una, y tienen una ruta con `GatewayId` igual al ID del endpoint (`vpce-...`).
- Aparece una tercera tabla, sin subredes y solo con la ruta `local`: es la tabla principal que AWS crea con toda VPC.
- La salida completa, con la policy restrictiva del endpoint, está en [PLAN_OUTPUT.md](PLAN_OUTPUT.md#6-aws-ec2-describe-vpc-endpoints).

### C7. Roles IAM

```bash
# Rol de procesamiento: quién lo asume y qué puede hacer
aws --endpoint-url=$EP iam get-role --role-name dataplat-dev-processing --query "Role.AssumeRolePolicyDocument"
aws --endpoint-url=$EP iam get-role-policy --role-name dataplat-dev-processing \
  --policy-name dataplat-dev-processing-s3-prefix --query "PolicyDocument"

# Rol de auditoría: quién lo asume y qué puede leer
aws --endpoint-url=$EP iam get-role --role-name dataplat-dev-audit-readonly --query "Role.AssumeRolePolicyDocument"
aws --endpoint-url=$EP iam get-role-policy --role-name dataplat-dev-audit-readonly \
  --policy-name dataplat-dev-audit-readonly --query "PolicyDocument"
```

**Esperado, rol de procesamiento:**
- Trust solo para `lambda.amazonaws.com` y `kinesisanalytics.amazonaws.com`, con la condición `aws:SourceAccount`.
- Permisos: `s3:ListBucket` sobre el bucket, limitado por la condición `s3:prefix = processed/`, y `s3:GetObject` / `s3:PutObject` sobre `<bucket>/processed/*`. Nada más: no tiene `DeleteObject` ni acceso a `raw/`.

**Esperado, rol de auditoría:**
- Trust para la cuenta, con la condición `aws:MultiFactorAuthPresent = true`.
- Permisos: solo acciones `Get*` y `List*` de configuración, listadas una por una, sobre el bucket del data lake y los dos roles. No incluye `s3:GetObject`: audita la configuración, no lee los datos.

### C8. Ningún permiso con `"*"`

```bash
# Desde la raíz del repo: líneas de código (sin comentarios) que contienen un *
cd ../.. && grep -rn '\*' --include=main.tf modules environments | grep -v '#'; cd environments/dev

# En las políticas ya desplegadas: no aparece ningún "*" suelto
aws --endpoint-url=$EP iam get-role-policy --role-name dataplat-dev-processing \
  --policy-name dataplat-dev-processing-s3-prefix | grep -c '"\*"'
aws --endpoint-url=$EP iam get-role-policy --role-name dataplat-dev-audit-readonly \
  --policy-name dataplat-dev-audit-readonly | grep -c '"\*"'
```

**Esperado:**
- **Primer comando:** busca en los `main.tf`, que es donde se escriben las políticas (en los `variables.tf` el `*` aparece solo dentro de expresiones regulares de validación). Devuelve solo tres líneas, y en las tres el `*` es el **sufijo de un ARN o de un prefijo**:
  - `"${var.processing_prefix}*"` (condición de ListBucket);
  - `"${var.data_bucket_arn}/${var.processing_prefix}*"` (objetos de `processed/`);
  - `"${arn}/*"` (objetos del bucket en la policy del endpoint).
  
  Ese sufijo **acota** el permiso a una carpeta o a un bucket. No hay `Action: "*"`, `s3:*`, `Resource: "*"` ni `Principal: "*"`.
- **Los dos `grep -c`:** `0`.

### C9. Outputs

```bash
tflocal output
```

**Esperado:** `vpc_id`, `private_subnet_ids` (lista de 2), `processing_role_arn` y `audit_role_arn`, más `s3_vpc_endpoint_id` y los datos del bucket.

Terraform también muestra el aviso `Deprecated Parameter` sobre `dynamodb_table`. Es esperable: ver [State y secretos](#state-y-secretos).

### C10. Validación (validate, tflint, plan, apply)

```bash
tflocal fmt -check -recursive ../..   # sin salida = formato correcto
tflocal validate                      # Success! The configuration is valid.
(cd ../.. && tflint --recursive)      # sin salida y exit code 0
tflocal plan                          # después del apply: "0 to add, 1 to change, 0 to destroy" (ver abajo)
```

- El primer `plan` y el `apply` crean **18 recursos**.
- Después del apply, LocalStack muestra un cambio en la policy del endpoint que no existe: guarda la policy sin el campo `Version`. En AWS real el plan da `No changes`. El detalle está en [PLAN_OUTPUT.md](PLAN_OUTPUT.md#8-state-remoto-y-segundo-plan).

### C11. PLAN_OUTPUT.md

[PLAN_OUTPUT.md](PLAN_OUTPUT.md) tiene las salidas reales, copiadas sin editar:
- versiones;
- `validate`;
- `tflint`;
- `plan`: 18 recursos a crear;
- `apply`: 18 creados, con los outputs;
- `describe-vpc-endpoints`, con el endpoint S3 y su policy;
- la verificación de IGW, subredes y rutas;
- el state en S3;
- el segundo plan.

### C12. Nada sensible en el repo

```bash
cd ../.. && git ls-files | grep -E '\.terraform/|\.tfstate|checkpoints/'; echo "coincidencias: $?"
```

**Esperado:** ninguna línea y `coincidencias: 1`: `grep` no encontró nada.
- El token de LocalStack solo existe como variable de entorno.
- `.terraform.lock.hcl` **sí** se versiona a propósito, para que todos usen la misma versión del provider.

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

### ¿Por qué separar en varios archivos y no un único `main.tf`?

Terraform lee todos los `.tf` de una carpeta como si fueran un solo archivo, así que separarlos no cambia el resultado: es para las personas que leen y revisan el código. Cada archivo responde una pregunta:

| Archivo | Pregunta que responde | Quién lo toca |
|---|---|---|
| `versions.tf` / `provider.tf` | ¿Qué versiones de Terraform y del provider? ¿Contra qué región y con qué tags? | Casi nunca; un cambio acá afecta todo |
| `backend.tf` | ¿Dónde se guarda el state y cómo se bloquea? | Una vez por entorno |
| `variables.tf` | ¿Qué se puede configurar desde afuera? Es el "contrato" del módulo o entorno | Quien agrega una opción nueva |
| `main.tf` | ¿Qué recursos se crean y cómo se conectan? | El día a día |
| `outputs.tf` | ¿Qué datos se exponen para que otros los consuman? | Quien necesita conectar piezas |
| `terraform.tfvars` | ¿Con qué valores concretos se despliega este entorno? | Cambia entre dev y prod; el código no |

Las ventajas concretas:
- **Code reviews más claras:** un PR que solo toca `terraform.tfvars` cambia valores, no lógica.
- **Menos conflictos en git** cuando varias personas trabajan a la vez.
- **Módulos fáciles de usar:** para saber cómo usar `modules/network` alcanza con leer su `variables.tf` y su `outputs.tf`, sin entrar al `main.tf`.

Con el mismo criterio, el código está separado en **módulos por dominio** (red e identidad) y en **entornos que los componen** (`environments/dev`), en vez de un módulo gigante que haga todo.

---

## Módulos

### `modules/network`

| Variable | Tipo | Default | Descripción |
|---|---|---|---|
| `name_prefix` | `string` | — | Prefijo de nombres (`dataplat-dev`) |
| `vpc_cidr` | `string` | — | CIDR de la VPC |
| `availability_zones` | `list(string)` | — | Una subred privada por zona; mínimo 2, sin repetir |
| `subnet_newbits` | `number` | `8` | Bits extra para cada subred (`/16` + 8 = `/24`) |
| `s3_endpoint_bucket_arns` | `list(string)` | — | Buckets a los que se puede llegar por el endpoint de S3 (mínimo 1) |
| `s3_endpoint_allowed_principal_arns` | `list(string)` | — | Roles o usuarios IAM que pueden usar el endpoint (mínimo 1) |
| `s3_endpoint_allowed_actions` | `list(string)` | `ListBucket`, `GetObject`, `PutObject` | Acciones de S3 permitidas por el endpoint, sin comodines |
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
- **Policy restrictiva en el endpoint:** sin policy, AWS deja el endpoint con acceso total a cualquier bucket de cualquier cuenta, lo que permitiría sacar datos de la VPC a un bucket ajeno. La policy limita el endpoint a:
  - **Principal:** solo el rol de procesamiento (llega por output del módulo identity), no `"*"`.
  - **Action:** solo `s3:ListBucket`, `s3:GetObject` y `s3:PutObject`, listadas una por una.
  - **Resource:** solo el bucket del data lake y sus objetos. El ARN llega por output, nunca escrito a mano.
  - El único `*` es el sufijo `<bucket>/*` del recurso: es la forma que tiene AWS de nombrar "los objetos de este bucket" y no se puede evitar sin listar cada objeto. No abre el acceso a otros buckets.
  - Es un segundo filtro: un pedido a S3 desde la VPC tiene que cumplir la policy del endpoint **y** la política IAM del rol.
  - En LocalStack, después del `apply` el `plan` sigue mostrando un cambio en esta policy: LocalStack guarda la policy sin el campo `Version` y Terraform quiere volver a agregarlo. En AWS real no pasa. Detalle en [PLAN_OUTPUT.md](PLAN_OUTPUT.md).
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

### Protección contra borrados y blast radius

- **`prevent_destroy` no se usa en dev, a propósito.** `lifecycle { prevent_destroy = true }` hace que Terraform se niegue a borrar un recurso: es la protección recomendada para el storage crítico de producción. Hay dos motivos para no usarlo acá:
  - En dev, LocalStack se recrea seguido y `tflocal destroy` tiene que poder limpiar todo.
  - `prevent_destroy` no acepta variables: no se puede escribir `prevent_destroy = var.environment == "prod"`. Si estuviera en el código compartido, también bloquearía dev.
- **Cómo se protege prod:**
  - `force_destroy = var.environment != "prod"`: en prod, Terraform no puede borrar el bucket del data lake si tiene objetos.
  - El versionado del bucket permite recuperar objetos sobrescritos o borrados.
  - En el root module de prod (`environments/prod/main.tf`) se agregaría `prevent_destroy = true` al bucket del data lake. Ese archivo es solo de prod y no afecta a dev.
- **Un state por entorno:** cada entorno tiene su propia `key` en el backend (`environments/dev/terraform.tfstate`, `environments/prod/terraform.tfstate`).
  - Un `apply` o `destroy` en `environments/dev` no puede tocar prod.
  - Por eso los entornos son carpetas separadas y no un `for_each` sobre `["dev", "prod"]`: con un `for_each`, dev y prod compartirían el mismo state.
- **Próximo paso, states por dominio:** hoy cada entorno tiene un solo state con red, IAM y data lake, que son 18 recursos y se planifican rápido. Cuando se sumen Kinesis, Flink y Redshift conviene separarlos en proyectos independientes (red, identidad, ingesta, procesamiento), cada uno con su `key`.
  - Los states chicos son más rápidos de planificar.
  - Reducen el **blast radius**: un error o un lock trabado en el state de Flink no impide cambiar la red.
  - Los módulos ya están separados por dominio, así que la división es mover las llamadas a carpetas distintas y conectarlas con `terraform_remote_state` o con *data sources*.

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
