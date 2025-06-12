# AWS Infraestructura para Ecommerce con Terraform y Ansible

## Descripción del Proyecto

Este proyecto implementa una infraestructura en AWS para una empresa ficticia de ecommerce que experimenta picos de tráfico en días festivos. El objetivo es proporcionar una solución flexible y parametrizable, permitiendo a un administrador desplegar y configurar la infraestructura según las necesidades del negocio.

La arquitectura incluye:
- Instancias EC2 para servidores web ("slaves") y una instancia EC2 "master" para administración.
- Infraestructura de red segura y escalable (VPC, subredes públicas, gateways, grupos de seguridad).
- Acceso SSH individualizado para cada instancia.
- Ejecución de playbooks de Ansible desde la instancia master hacia las instancias web, permitiendo la configuración y gestión remota de los servidores.

Esta solución NO es automatizada: el administrador es responsable de ejecutar los playbooks de Ansible según los requerimientos operativos.
[Link del repositorio](https://github.com/FranciscoFerrutti/Ansible-Impl)
## Características
- Parametrización de la cantidad de instancias web y sus recursos.
- Definición de credenciales SSH para cada instancia.
- Configuración de horarios de atención HTTP mediante Ansible.
- Infraestructura reproducible y versionada con Terraform.

## Instalación y Configuración

### 1. Requisitos previos
- Tener una cuenta de AWS con permisos suficientes para crear recursos (EC2, VPC, buckets s3, etc.).
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
terraform plan -out tf.out
terraform apply tf.out
```

> **Nota:** El archivo `terraform.tfvars` ya contiene los parámetros necesarios, por lo que no es necesario especificarlo manualmente.

### 4. Acceso y administración
- Una vez desplegada la infraestructura, accede a la instancia master vía SSH usando la clave generada.
- Desde la master, puedes ejecutar playbooks de Ansible para configurar y gestionar las instancias web.

### 5. Instalacion de AWX en la EC2 master
- Una vez conectado por SSH a la EC2 master hay que ejecutar los siguientes comandos 1 por 1.
```bash
sudo apt update -y && sudo apt upgrade -y
sudo apt install docker.io make

# instalar minikube
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64
sudo usermod -aG docker $USER && newgrp docker

# clonar awx-operator repo
git clone https://github.com/ansible/awx-operator.git
cd awx-operator
git checkout tags/2.4.0
export VERSION=2.4.0
echo "# kustomization.yml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- github.com/ansible/awx-operator/config/default?ref=2.4.0
- awx-demo.yml
images:
- name: quay.io/ansible/awx-operator
newTag: 2.4.0

namespace: awx" > kustomization.yml
echo "# awx-demo.yml
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
name: awx-demo
spec:
service_type: nodeport" > awx-demo.yml
minikube start --cpus=2 --memory=6g --addons=ingress
exit # Exit the docker user group
alias kubectl="minikube kubectl --"

kubectl get nodes
# deberia retornar 1 nodo lamado "minikube" con status READY
kubectl get pods -A
# deberia retornar 3 nginx namespaces y otros 7 llamados "kube-system"

cd ~/awx-operator

kubectl apply -k .
kubectl apply -f awx-demo.yml
kubectl apply -k . # sanity checking

# Ahora hay que esperar entre 2 y 5 minutos a que se inicie

# Para chequear el estado de los pods usar:
kubectl get pods -A

# Para obtener la contraseña del usuario de awx. El usuario sera: admin
kubectl get secret -n awx awx-demo-admin-password -o jsonpath="{.data.password}" | base64 --decode

# Los pod "awx-demo-task" y "awx-demo web" pueden tener solo 3/4 y 2/3 containers listos, a causa de un "CrashLoopBack". 
Ignorarlo.
# Cuando se encuentren corriendo, necesitamos hacer port-forward para web-server corriendo en el clustre awx-demo-web port 80. Podemos portforwardear todas las ifaces port 8080 con este comando:

kubectl port-forward svc/awx-demo-service 8080:80 -n awx --address 0.0.0.0

# Listo. Awx se puede acceder el en puerto 8080 de la EC2 master con la contraseña obtenida y el usuario admin
```

### 6. Setup de awx
- Una vez dentro de awx, ir a Proyectos -> Añadir
- Seleccionar como tipo de fuente de control git
- Insertar el link del repositorio (que se encuentra arriba) en la rama /main
- Crear el proyecto
- Ir a inventarios y crear un inventario vacio, es decir no tocar nada y crearlo
- Entrar al inventario vacio, ir a fuentes -> Añadir
- Fuentre: Extraido de un proyecto, en proyecto seleccionar el creado anteriormente y en archivo de inventario slecionar el .ini
- Ir a Plantillas -> Añadir -> Plantilla de trabajo
- Seleccionar el inventario del paso anterior y el proyecto de hace 2 pasos. Clickear en el dropdown y seleccionar el playbook requerido
- Si el playbook requiere variables por "linea de comando" agregarlas en variables yml con el formato
        nombre_de_la_variable:"valor_de_la_variable"
- Crear el playbook y ejecutar



## Estructura del Proyecto

- `main.tf`, `variables.tf`, `outputs.tf`, `provider.tf`, `version.tf`: Archivos principales de Terraform.
- `terraform.tfvars`: Variables de configuración del despliegue.
- `modules/`: Módulos reutilizables para EC2 y VPC.

## Notas adicionales
- Recuerda destruir la infraestructura cuando no la necesites más con `terraform destroy`.
- Puedes modificar los parámetros en `terraform.tfvars` para ajustar la cantidad de instancias, recursos, etc.
- La seguridad y el acceso están gestionados mediante grupos de seguridad y claves SSH individuales.

## Integracion con TPE implementado por el grupo 4

### Prerequisitos
- Tener descargado el TPE del grupo 4 (https://github.com/avilamowski/tpe-redes-g4).
- Tener la EC2 master del proyecto ya levantada.

### Playbooks
**setup.yml**           : Prepara el ambiente en la EC2 master para el uso de playbooks ansible.
**upload.yml**          : Sube a la EC2 master el proyecto del grupo 4.
**exectue.yml**         : Ejecuta el terraform del grupo 4 para poder levantar el servidor de chat.
**terminate_ec2**       : Da de baja la instancia EC2 seleccionada.
        - Comando de uso: ansible-playbook terminate_ec2.yml -e "instance_id=......"
**launcher.yml**        : Lanza una instancia EC2 en al subnet deseada.
        - Comando de uso: ansible-playbook launch_ec2.yml -e "subnet_id=......."
**update.yml**          : Update del firewall que corre como servicio en las web instances.
        - Comando de uso: ansible-playbook update_firewalld.yml -i "{{ host }}, " --extra-vars "target_host=....." --ssh-extra-args='-o StrictHostKeyChecking=no'

## Autores
- Francisco Ferrutti (62780)
- Guido De Caro (61590)
- Lucas David Perri (62746)
