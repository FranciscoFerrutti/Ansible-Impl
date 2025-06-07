# AWS Infraestructura para Ecommerce con Terraform y Ansible

## Descripción del Proyecto

Este proyecto implementa una infraestructura en AWS para una empresa ficticia de ecommerce que experimenta picos de tráfico en días festivos. El objetivo es proporcionar una solución flexible y parametrizable, permitiendo a un administrador desplegar y configurar la infraestructura según las necesidades del negocio.

La arquitectura incluye:
- Instancias EC2 para servidores web ("slaves") y una instancia EC2 "master" para administración.
- Infraestructura de red segura y escalable (VPC, subredes públicas, gateways, grupos de seguridad).
- Acceso SSH individualizado para cada instancia.
- Ejecución de playbooks de Ansible desde la instancia master hacia las instancias web, permitiendo la configuración y gestión remota de los servidores.

Esta solución NO es automatizada: el administrador es responsable de ejecutar los playbooks de Ansible según los requerimientos operativos.

## Características
- Parametrización de la cantidad de instancias web y sus recursos.
- Definición de credenciales SSH para cada instancia.
- Configuración de horarios de atención HTTP mediante Ansible.
- Infraestructura reproducible y versionada con Terraform.

## Instalación y Configuración

### 1. Requisitos previos
- Tener una cuenta de AWS con permisos suficientes para crear recursos (EC2, VPC, etc.).
- Instalar [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- Instalar [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

### 2. Configuración de credenciales AWS
Configura tus credenciales en el archivo `~/.aws/credentials` (o `%USERPROFILE%\.aws\credentials` en Windows):

```
[default]
aws_access_key_id = TU_ACCESS_KEY
aws_secret_access_key = TU_SECRET_KEY
aws_session_token = TU_TOKEN
```

### 3. Despliegue de la infraestructura
Desde la raíz del proyecto, ejecuta:

```powershell
terraform init
terraform plan
terraform apply
```

> **Nota:** El archivo `terraform.tfvars` ya contiene los parámetros necesarios, por lo que no es necesario especificarlo manualmente.

### 4. Acceso y administración
- Una vez desplegada la infraestructura, accede a la instancia master vía SSH usando la clave generada.
- Desde la master, puedes ejecutar playbooks de Ansible para configurar y gestionar las instancias web.

## Estructura del Proyecto

- `main.tf`, `variables.tf`, `outputs.tf`, `provider.tf`, `version.tf`: Archivos principales de Terraform.
- `terraform.tfvars`: Variables de configuración del despliegue.
- `modules/`: Módulos reutilizables para EC2 y VPC.

## Notas adicionales
- Recuerda destruir la infraestructura cuando no la necesites más con `terraform destroy`.
- Puedes modificar los parámetros en `terraform.tfvars` para ajustar la cantidad de instancias, recursos, etc.
- La seguridad y el acceso están gestionados mediante grupos de seguridad y claves SSH individuales.

## Autores
- [Francisco Ferrutti](https://github.com/FranciscoFerrutti)
- 
- 
