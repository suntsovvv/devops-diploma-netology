# Дипломный практикум в Yandex.Cloud
  * [Цели:](#цели)
  * [Этапы выполнения:](#этапы-выполнения)
     * [Создание облачной инфраструктуры](#создание-облачной-инфраструктуры)
     * [Создание Kubernetes кластера](#создание-kubernetes-кластера)
     * [Создание тестового приложения](#создание-тестового-приложения)
     * [Подготовка cистемы мониторинга и деплой приложения](#подготовка-cистемы-мониторинга-и-деплой-приложения)
     * [Установка и настройка CI/CD](#установка-и-настройка-cicd)
  * [Что необходимо для сдачи задания?](#что-необходимо-для-сдачи-задания)
  * [Как правильно задавать вопросы дипломному руководителю?](#как-правильно-задавать-вопросы-дипломному-руководителю)

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**

---
## Цели:

1. Подготовить облачную инфраструктуру на базе облачного провайдера Яндекс.Облако.
2. Запустить и сконфигурировать Kubernetes кластер.
3. Установить и настроить систему мониторинга.
4. Настроить и автоматизировать сборку тестового приложения с использованием Docker-контейнеров.
5. Настроить CI для автоматической сборки и тестирования.
6. Настроить CD для автоматического развёртывания приложения.

---
## Этапы выполнения:


### Создание облачной инфраструктуры

Для начала необходимо подготовить облачную инфраструктуру в ЯО при помощи [Terraform](https://www.terraform.io/).

Особенности выполнения:

- Бюджет купона ограничен, что следует иметь в виду при проектировании инфраструктуры и использовании ресурсов;
Для облачного k8s используйте региональный мастер(неотказоустойчивый). Для self-hosted k8s минимизируйте ресурсы ВМ и долю ЦПУ. В обоих вариантах используйте прерываемые ВМ для worker nodes.

Предварительная подготовка к установке и запуску Kubernetes кластера.

1. Создайте сервисный аккаунт, который будет в дальнейшем использоваться Terraform для работы с инфраструктурой с необходимыми и достаточными правами. Не стоит использовать права суперпользователя
2. Подготовьте [backend](https://www.terraform.io/docs/language/settings/backends/index.html) для Terraform:  
   а. Рекомендуемый вариант: S3 bucket в созданном ЯО аккаунте(создание бакета через TF)
   б. Альтернативный вариант:  [Terraform Cloud](https://app.terraform.io/)
3. Создайте конфигурацию Terrafrom, используя созданный бакет ранее как бекенд для хранения стейт файла. Конфигурации Terraform для создания сервисного аккаунта и бакета и основной инфраструктуры следует сохранить в разных папках.
4. Создайте VPC с подсетями в разных зонах доступности.
5. Убедитесь, что теперь вы можете выполнить команды `terraform destroy` и `terraform apply` без дополнительных ручных действий.
6. В случае использования [Terraform Cloud](https://app.terraform.io/) в качестве [backend](https://www.terraform.io/docs/language/settings/backends/index.html) убедитесь, что применение изменений успешно проходит, используя web-интерфейс Terraform cloud.

Ожидаемые результаты:

1. Terraform сконфигурирован и создание инфраструктуры посредством Terraform возможно без дополнительных ручных действий, стейт основной конфигурации сохраняется в бакете или Terraform Cloud
2. Полученная конфигурация инфраструктуры является предварительной, поэтому в ходе дальнейшего выполнения задания возможны изменения.
## Решение:
Написал Конфигурацию [Terraform-for-backet](https://www.terraform.io/) для  создания сервисного аккаунта, который будет в дальнейшем использоваться Terraform для работы с инфраструктурой с необходимыми и достаточными правами.
```hcl
resource "yandex_iam_service_account" "sa" {
  name = "sa-for-bucket"
}

# Назначение роли сервисному аккаунту
resource "yandex_resourcemanager_folder_iam_member" "sa-editor" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

# Создание статического ключа доступа
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.sa.id
}

# Создание бакета с использованием ключа
resource "yandex_storage_bucket" "tstate" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket     = "bucket-suntsovvv-2025"
  acl    = "private"
  force_destroy = true
```
Так же в ней создается файл конфигурации для для подключения бэкенда терраформ к s3 backet.
```hcl
# Создание файла конфигурации для подключения бэкэнда terraform к S3
resource "local_file" "backend" {
  content  = <<EOT
bucket = "${yandex_storage_bucket.tstate.bucket}"
region = "ru-central1"
key = "terraform.tfstate"
access_key = "${yandex_iam_service_account_static_access_key.sa-static-key.access_key}"
secret_key = "${yandex_iam_service_account_static_access_key.sa-static-key.secret_key}"
EOT
  filename = "../terraform/secret.backend.tfvars"

}
```
Вотдельной папке создал конфигурацию [Terraform](https://www.terraform.io/), используя созданный бакет ранее как бекенд для хранения стейт файла. 
```hcl
terraform {
backend "s3" {
endpoint  = "https://storage.yandexcloud.net" 
skip_region_validation = true
skip_credentials_validation = true
skip_requesting_account_id  = true # необходимая опция при описании бэкенда для Terraform версии 1.6.1 и старше.
skip_s3_checksum            = true # необходимая опция при описании бэкенда для Terraform версии 1.6.3 и старше.
}
}
  
```
Для инициализации конфигурации неообходимо использовать команду c указанием файла конфигурации , полученного при выполнении конфигурации Terraform-for-backet.
```bash
user@microk8s:~/devops-diploma-netology/terraform$ terraform init -backend-config secret.backend.tfvars 
Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
Initializing provider plugins...
- Finding latest version of yandex-cloud/yandex...
- Installing yandex-cloud/yandex v0.135.0...
- Installed yandex-cloud/yandex v0.135.0 (unauthenticated)
Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

╷
│ Warning: Incomplete lock file information for providers
│ 
│ Due to your customized provider installation methods, Terraform was forced to calculate lock file checksums locally for the following providers:
│   - yandex-cloud/yandex
│ 
│ The current .terraform.lock.hcl file only includes checksums for linux_amd64, so Terraform running on another platform will fail to install these providers.
│ 
│ To calculate additional checksums for another platform, run:
│   terraform providers lock -platform=linux_amd64
│ (where linux_amd64 is the platform to generate)
╵
Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```
Создал VPC с подсетями в разных зонах доступности.
```hcl
resource "yandex_vpc_network" "k8s" {
  name = var.vpc_name
}

# Создание подсетей
resource "yandex_vpc_subnet" "ru-central1-a" {
  zone           = var.subnet_zone[0]
  name = "ru-central1-a"
  network_id     = "${yandex_vpc_network.k8s.id}"
  v4_cidr_blocks = ["${var.cidr[0]}"]
  route_table_id = yandex_vpc_route_table.nat-instance-route.id

}
resource "yandex_vpc_subnet" "ru-central1-b" {
  zone           = var.subnet_zone[1]
  name = "ru-central1-b"
  network_id     = "${yandex_vpc_network.k8s.id}"
  v4_cidr_blocks = ["${var.cidr[1]}"]
  route_table_id = yandex_vpc_route_table.nat-instance-route.id

}

resource "yandex_vpc_subnet" "ru-central1-d" {
  zone           = var.subnet_zone[2]
  name = "ru-central1-d"
  network_id     = "${yandex_vpc_network.k8s.id}"
  v4_cidr_blocks = ["${var.cidr[2]}"]
  route_table_id = yandex_vpc_route_table.nat-instance-route.id
}
resource "yandex_vpc_subnet" "bastion-nat" {
  zone           = var.subnet_zone[0]
  name = "k8s-out"
  network_id     = "${yandex_vpc_network.k8s.id}"
  v4_cidr_blocks = ["${var.cidr[3]}"]

}
```
Результаты применеия конфигурвций:
![image](https://github.com/user-attachments/assets/0f778ca5-e301-4c29-a4a0-efdf8c022d31)
![image](https://github.com/user-attachments/assets/10736b75-2c79-4210-ac53-9fe408aab562)
![image](https://github.com/user-attachments/assets/76b49466-9fe9-408e-a2fd-27a3c03cbf74)
Убедился , что теперь вы можете выполнить команды `terraform destroy` и `terraform apply` без дополнительных ручных действий.
```bash
ser@microk8s:~/devops-diploma-netology/terraform$ terraform destroy
yandex_vpc_network.develop: Refreshing state... [id=enp4kg7up291o0faqtqv]
yandex_vpc_subnet.subnet_zones[0]: Refreshing state... [id=e9bkotjbugv66js68u84]
yandex_vpc_subnet.subnet_zones[1]: Refreshing state... [id=e2l1trvuihvq0uqdldfh]
yandex_vpc_subnet.subnet_zones[2]: Refreshing state... [id=fl8194jj1vic23i63sjt]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # yandex_vpc_network.develop will be destroyed
  - resource "yandex_vpc_network" "develop" {
      - created_at                = "2025-01-14T01:24:39Z" -> null
      - default_security_group_id = "enp1bah2876m7cchqjtm" -> null
      - folder_id                 = "b1gpta86451pk7tseq2b" -> null
      - id                        = "enp4kg7up291o0faqtqv" -> null
      - labels                    = {} -> null
      - name                      = "VPC-k8s" -> null
      - subnet_ids                = [
          - "e2l1trvuihvq0uqdldfh",
          - "e9bkotjbugv66js68u84",
          - "fl8194jj1vic23i63sjt",
        ] -> null
        # (1 unchanged attribute hidden)
    }

  # yandex_vpc_subnet.subnet_zones[0] will be destroyed
  - resource "yandex_vpc_subnet" "subnet_zones" {
      - created_at     = "2025-01-14T01:24:44Z" -> null
      - folder_id      = "b1gpta86451pk7tseq2b" -> null
      - id             = "e9bkotjbugv66js68u84" -> null
      - labels         = {} -> null
      - name           = "subnet-ru-central1-a" -> null
      - network_id     = "enp4kg7up291o0faqtqv" -> null
      - v4_cidr_blocks = [
          - "10.10.1.0/24",
        ] -> null
      - v6_cidr_blocks = [] -> null
      - zone           = "ru-central1-a" -> null
        # (2 unchanged attributes hidden)
    }

  # yandex_vpc_subnet.subnet_zones[1] will be destroyed
  - resource "yandex_vpc_subnet" "subnet_zones" {
      - created_at     = "2025-01-14T01:24:45Z" -> null
      - folder_id      = "b1gpta86451pk7tseq2b" -> null
      - id             = "e2l1trvuihvq0uqdldfh" -> null
      - labels         = {} -> null
      - name           = "subnet-ru-central1-b" -> null
      - network_id     = "enp4kg7up291o0faqtqv" -> null
      - v4_cidr_blocks = [
          - "10.10.2.0/24",
        ] -> null
      - v6_cidr_blocks = [] -> null
      - zone           = "ru-central1-b" -> null
        # (2 unchanged attributes hidden)
    }

  # yandex_vpc_subnet.subnet_zones[2] will be destroyed
  - resource "yandex_vpc_subnet" "subnet_zones" {
      - created_at     = "2025-01-14T01:24:44Z" -> null
      - folder_id      = "b1gpta86451pk7tseq2b" -> null
      - id             = "fl8194jj1vic23i63sjt" -> null
      - labels         = {} -> null
      - name           = "subnet-ru-central1-d" -> null
      - network_id     = "enp4kg7up291o0faqtqv" -> null
      - v4_cidr_blocks = [
          - "10.10.3.0/24",
        ] -> null
      - v6_cidr_blocks = [] -> null
      - zone           = "ru-central1-d" -> null
        # (2 unchanged attributes hidden)
    }

Plan: 0 to add, 0 to change, 4 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

yandex_vpc_subnet.subnet_zones[1]: Destroying... [id=e2l1trvuihvq0uqdldfh]
yandex_vpc_subnet.subnet_zones[0]: Destroying... [id=e9bkotjbugv66js68u84]
yandex_vpc_subnet.subnet_zones[2]: Destroying... [id=fl8194jj1vic23i63sjt]
yandex_vpc_subnet.subnet_zones[2]: Destruction complete after 1s
yandex_vpc_subnet.subnet_zones[1]: Destruction complete after 1s
yandex_vpc_subnet.subnet_zones[0]: Destruction complete after 2s
yandex_vpc_network.develop: Destroying... [id=enp4kg7up291o0faqtqv]
yandex_vpc_network.develop: Destruction complete after 1s

Destroy complete! Resources: 4 destroyed.
user@microk8s:~/devops-diploma-netology/terraform$ terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_vpc_network.develop will be created
  + resource "yandex_vpc_network" "develop" {
      + created_at                = (known after apply)
      + default_security_group_id = (known after apply)
      + folder_id                 = (known after apply)
      + id                        = (known after apply)
      + labels                    = (known after apply)
      + name                      = "VPC-k8s"
      + subnet_ids                = (known after apply)
    }

  # yandex_vpc_subnet.subnet_zones[0] will be created
  + resource "yandex_vpc_subnet" "subnet_zones" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-ru-central1-a"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.10.1.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-a"
    }

  # yandex_vpc_subnet.subnet_zones[1] will be created
  + resource "yandex_vpc_subnet" "subnet_zones" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-ru-central1-b"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.10.2.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-b"
    }

  # yandex_vpc_subnet.subnet_zones[2] will be created
  + resource "yandex_vpc_subnet" "subnet_zones" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-ru-central1-d"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.10.3.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-d"
    }

Plan: 4 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

yandex_vpc_network.develop: Creating...
yandex_vpc_network.develop: Creation complete after 2s [id=enp7b4luklr8evdoiala]
yandex_vpc_subnet.subnet_zones[2]: Creating...
yandex_vpc_subnet.subnet_zones[0]: Creating...
yandex_vpc_subnet.subnet_zones[1]: Creating...
yandex_vpc_subnet.subnet_zones[0]: Creation complete after 1s [id=e9bnd2n77dbe87bck7v6]
yandex_vpc_subnet.subnet_zones[2]: Creation complete after 2s [id=fl83r4aa2jtl1orm8c60]
yandex_vpc_subnet.subnet_zones[1]: Creation complete after 2s [id=e2l8t85dhubj8bn6oldf]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```


---
### Создание Kubernetes кластера

На этом этапе необходимо создать [Kubernetes](https://kubernetes.io/ru/docs/concepts/overview/what-is-kubernetes/) кластер на базе предварительно созданной инфраструктуры.   Требуется обеспечить доступ к ресурсам из Интернета.

Это можно сделать двумя способами:

1. Рекомендуемый вариант: самостоятельная установка Kubernetes кластера.  
   а. При помощи Terraform подготовить как минимум 3 виртуальных машины Compute Cloud для создания Kubernetes-кластера. Тип виртуальной машины следует выбрать самостоятельно с учётом требовании к производительности и стоимости. Если в дальнейшем поймете, что необходимо сменить тип инстанса, используйте Terraform для внесения изменений.  
   б. Подготовить [ansible](https://www.ansible.com/) конфигурации, можно воспользоваться, например [Kubespray](https://kubernetes.io/docs/setup/production-environment/tools/kubespray/)  
   в. Задеплоить Kubernetes на подготовленные ранее инстансы, в случае нехватки каких-либо ресурсов вы всегда можете создать их при помощи Terraform.
2. Альтернативный вариант: воспользуйтесь сервисом [Yandex Managed Service for Kubernetes](https://cloud.yandex.ru/services/managed-kubernetes)  
  а. С помощью terraform resource для [kubernetes](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_cluster) создать **региональный** мастер kubernetes с размещением нод в разных 3 подсетях      
  б. С помощью terraform resource для [kubernetes node group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_node_group)
  
Ожидаемый результат:

1. Работоспособный Kubernetes кластер.
2. В файле `~/.kube/config` находятся данные для доступа к кластеру.
3. Команда `kubectl get pods --all-namespaces` отрабатывает без ошибок.
## Решение:
Для развертывания кластера используются версии ПО:   
Terraform v1.10.5-dev   
ansible [core 2.16.3]   
Ubuntu 22.04.5 LTS   
Подготовил конфигурацию для создания одной master-ноды и нескольких worker-нод [terraform](https://github.com/suntsovvv/devops-diploma-netology/tree/main/terraform)   
Также дополнительно добавил бастион хост, для того чтобы кластер не светил в Интернет белыми ip нод и иметь к доступ к его конфигурации, доступ к приложению и web-интерфейсу мониторинга в дальнейшем будет обеспечен при помощи балансировщика.   
Занчения для переменных неодходимо указывать в файле personal.auto.tfvars который имеет структуру:
```yaml
cloud_id = " "
folder_id = " "
zone = "ru-central1-a"
token = " "
vpc_name = "VPC-k8s"
subnet_zone = ["ru-central1-a","ru-central1-b","ru-central1-d"]
cidr = ["10.10.1.0/24","10.10.2.0/24","10.10.3.0/24","10.0.0.0/24"]

master = {
    cores = 4, 
    memory = 4, 
    core_fraction = 20,  
    platform_id = "standard-v3", 
    count = 1,image_id = "fd8slhpjt2754igimqu8", 
    disk_sze = 40,
    scheduling_policy = "true"
    }

worker = {
    cores = 4, 
    memory = 4, 
    core_fraction = 20,  
    platform_id = "standard-v3", 
    count = 2,image_id = "fd8slhpjt2754igimqu8", 
    disk_sze = 40,
    scheduling_policy = "true"
    } 

bastion = {
    cores = 2, 
    memory = 2, 
    core_fraction = 20, 
    image_id = "fd8m30o437b5c6b9en6r", 
    disk_sze = 20,
    scheduling_policy = "true"
    }

```
В результате применения конфигурации,  так же атоматически создается файл с инвентарем для ansible hosts.yaml следующего вида:   
```yaml 
all:
    hosts:
        k8s-master:
            ansible_host:
            ip: 10.10.1.6
            ansible_user: ubuntu
            ansible_ssh_common_args: -J ubuntu@89.169.129.228

        k8s-worker-1:
            ansible_host:
            ip: 10.10.1.7
            ansible_user: ubuntu
            ansible_ssh_common_args: -J ubuntu@89.169.129.228
        
        k8s-worker-2:
            ansible_host:
            ip: 10.10.2.22
            ansible_user: ubuntu
            ansible_ssh_common_args: -J ubuntu@89.169.129.228
         
        
        
kube_control_plane:
    hosts: 
        k8s-master:
kube_node:
    hosts:
        k8s-worker-1:
        k8s-worker-2:
etcd:
    hosts: 
        k8s-master:
```
 на основе шаблона inventory.tftpl:
```
all:
    hosts:
        k8s-master:
            ansible_host:
            ip: ${k8s-master.network_interface[0].ip_address}
            ansible_user: ubuntu
            ansible_ssh_common_args: -J ubuntu@${bastion-nat.network_interface[0].nat_ip_address}

        k8s-worker-1:
            ansible_host:
            ip: ${k8s-worker-1.network_interface[0].ip_address}
            ansible_user: ubuntu
            ansible_ssh_common_args: -J ubuntu@${bastion-nat.network_interface[0].nat_ip_address}
        
        k8s-worker-2:
            ansible_host:
            ip: ${k8s-worker-2.network_interface[0].ip_address}
            ansible_user: ubuntu
            ansible_ssh_common_args: -J ubuntu@${bastion-nat.network_interface[0].nat_ip_address}
         
        
        
kube_control_plane:
    hosts: 
        k8s-master:
kube_node:
    hosts:
        k8s-worker-1:
        k8s-worker-2:
etcd:
    hosts: 
        k8s-master:

```
Для удобства добавил output c выводом белого ip бастион хоста и внутренним ip master-ноды.   
Результат применения:
```bash
user@microk8s:~/devops-diploma-netology/terraform$ terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
...................................................................
 

Apply complete! Resources: 14 added, 0 changed, 0 destroyed.

Outputs:

all_vms = {
  "bastion-nat" = [
    {
      "name" = "bastion-nat"
      "nat_ip_address" = "89.169.129.228"
    },
  ]
  "master" = [
    {
      "ip_address" = "10.10.1.6"
      "name" = "k8s-master"
    },
  ]
}
```
![image](https://github.com/user-attachments/assets/d14957e6-fb8e-49d3-8a29-7b4e1a3d4a12)

Проверяю доступ в к кластеру через бастион хост:
```bash
ssh ubuntu@10.10.1.6 -J ubuntu@89.169.129.228 
The authenticity of host '89.169.129.228 (89.169.129.228)' can't be established.
ED25519 key fingerprint is SHA256:jhXvcablVsCW7dapkwiWC0r7Ax/ZkRZEh9JqzOui1/g.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '89.169.129.228' (ED25519) to the list of known hosts.
The authenticity of host '10.10.1.6 (<no hostip for proxy command>)' can't be established.
ED25519 key fingerprint is SHA256:c8XLKNGX0omvR5LBxAfa+AkZkClCPKWjqKSnJknR9FM.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.10.1.6' (ED25519) to the list of known hosts.
Welcome to Ubuntu 22.04.5 LTS (GNU/Linux 5.15.0-130-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Mon Jan 27 10:39:40 AM UTC 2025

  System load:  0.0                Processes:             146
  Usage of /:   10.4% of 39.28GB   Users logged in:       0
  Memory usage: 6%                 IPv4 address for eth0: 10.10.1.6
  Swap usage:   0%

 * Strictly confined Kubernetes makes edge and IoT secure. Learn how MicroK8s
   just raised the bar for easy, resilient and secure K8s cluster deployment.

   https://ubuntu.com/engage/secure-kubernetes-at-the-edge

Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


The list of available updates is more than a week old.
To check for new updates run: sudo apt update


The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

ubuntu@k8s-master:~$ 
```
Далее был подготовлен набор ansible-ролей  [k8s](https://github.com/suntsovvv/devops-diploma-netology/tree/main/ansible/k8s)
В результате применения плейбука:   
```yaml
- name: install docker and kubectl
  hosts: all
  become: yes
  remote_user: ubuntu
  roles:
    - docker_install
    - k8s_install

- name: create cluster
  hosts: kube_control_plane
  become: yes
  remote_user: ubuntu
  roles:
    - k8s_create_cluster

- name: node invite
  hosts: kube_node
  become: yes
  remote_user: ubuntu
  roles:
    - node_invite
```
на инвентарь, полученный на предыдущем шаге, выполняется установка необходимого ПО, инициализация кластера, подключение worker-нод к кластеру и настройка kubectl .   
Применять необходимо командой *ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ../hosts.yaml playbook.yml -K*   
Ключ ANSIBLE_HOST_KEY_CHECKING=False, нужен для того чтобы не мешали запросы fingerprint, *-K* для того чтобы можно было задать пароль пользователя локальной машины, так как в результате выполнения роли k8s_create_cluster , будет создаваться файл на локальной машине для дальнейшего использования ролью node_invite. 

Применяю:
```bash
user@microk8s:~/devops-diploma-netology/ansible/k8s$ ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ../hosts.yaml playbook.yml -K
BECOME password:
................................................
 ____________
< PLAY RECAP >
 ------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||

k8s-master                 : ok=29   changed=24   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
k8s-worker-1               : ok=26   changed=21   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
k8s-worker-2               : ok=26   changed=21   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```
Проверяю:
```bash
ubuntu@k8s-master:~$ kubectl cluster-info
Kubernetes control plane is running at https://10.10.1.6:6443
CoreDNS is running at https://10.10.1.6:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
ubuntu@k8s-master:~$ kubectl get nodes 
NAME           STATUS   ROLES           AGE   VERSION
k8s-master     Ready    control-plane   17m   v1.30.9
k8s-worker-1   Ready    <none>          16m   v1.30.9
k8s-worker-2   Ready    <none>          16m   v1.30.9
ubuntu@k8s-master:~$ kubectl get pods --all-namespaces
NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE
kube-system   calico-kube-controllers-7dc5458bc6-27wj6   1/1     Running   0          16m
kube-system   calico-node-dl6xr                          1/1     Running   0          16m
kube-system   calico-node-kg76m                          1/1     Running   0          16m
kube-system   calico-node-ml78d                          1/1     Running   0          16m
kube-system   coredns-55cb58b774-mjdqn                   1/1     Running   0          16m
kube-system   coredns-55cb58b774-zzr4k                   1/1     Running   0          16m
kube-system   etcd-k8s-master                            1/1     Running   0          17m
kube-system   kube-apiserver-k8s-master                  1/1     Running   0          17m
kube-system   kube-controller-manager-k8s-master         1/1     Running   0          17m
kube-system   kube-proxy-4v2fp                           1/1     Running   0          16m
kube-system   kube-proxy-cpvc6                           1/1     Running   0          16m
kube-system   kube-proxy-qkcpg                           1/1     Running   0          16m
kube-system   kube-scheduler-k8s-master                  1/1     Running   0          17m
```
---
### Создание тестового приложения

Для перехода к следующему этапу необходимо подготовить тестовое приложение, эмулирующее основное приложение разрабатываемое вашей компанией.

Способ подготовки:

1. Рекомендуемый вариант:  
   а. Создайте отдельный git репозиторий с простым nginx конфигом, который будет отдавать статические данные.  
   б. Подготовьте Dockerfile для создания образа приложения.  
2. Альтернативный вариант:  
   а. Используйте любой другой код, главное, чтобы был самостоятельно создан Dockerfile.

Ожидаемый результат:

1. Git репозиторий с тестовым приложением и Dockerfile.
2. Регистри с собранным docker image. В качестве регистри может быть DockerHub или [Yandex Container Registry](https://cloud.yandex.ru/services/container-registry), созданный также с помощью terraform.

## Решение:
Создал дополнительный репозиторий https://github.com/suntsovvv/web-app-diploma.git   
Создал на DockerHub репозторий suntsovvv/web-app-diploma
Создал статичную web-страницу :
```html
<html>
 <head>
    <title>
        web-app-dipoma
    </title>
    <meta name="title" content="web-app-dipoma">
    <meta name="author" content="Suntsov VV">
 </head>
 <body> 
    <pre>
  hello this is version 1.0.0
  --------
     \   ^__^
      \  (oo)\_______
         (__)\       )\/\
             ||----w |
             ||     ||
    </pre>

 </body>
</html>
```
Далее создал Dockerfile:
```
FROM nginx:1.27.0
RUN rm -rf /usr/share/nginx/html/*
COPY index.html /usr/share/nginx/html/
EXPOSE 80
```
Залогинился на DockerHub:
```bash
root@astra:/home/user# docker login -u suntsovvv
Password: 
root@astra:/home/user# docker login -u suntsovvv@gmail.com
Password: 
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```
Создал docker образ:
```bash
root@astra:/home/user/testdocker# docker build . -t suntsovvv/web-app-diploma:1.0.0
Sending build context to Docker daemon  3.072kB
Step 1/4 : FROM nginx:1.27.0
 ---> 900dca2a61f5
Step 2/4 : RUN rm -rf /usr/share/nginx/html/*
 ---> Using cache
 ---> 4da2d5156a90
Step 3/4 : COPY /user/home/testdocker/index.html  /usr/share/nginx/
COPY failed: stat /var/lib/docker/tmp/docker-builder414349919/user/home/testdocker/index.html: no such file or directory
root@astra:/home/user/testdocker# nano Dockerfile 
root@astra:/home/user/testdocker# docker build . -t suntsovvv/web-app-diploma:1.0.0
Sending build context to Docker daemon  3.072kB
Step 1/4 : FROM nginx:1.27.0
 ---> 900dca2a61f5
Step 2/4 : RUN rm -rf /usr/share/nginx/html/*
 ---> Using cache
 ---> 4da2d5156a90
Step 3/4 : COPY index.html  /usr/share/nginx/html/
 ---> 1fe4fa6d593b
Step 4/4 : EXPOSE 80
 ---> Running in 770eab7b8160
Removing intermediate container 770eab7b8160
 ---> fd33e0f6f7be
Successfully built fd33e0f6f7be
```
Запушил образ на Hub:
```
root@astra:/home/user/testdocker# docker push  suntsovvv/web-app-diploma:1.0.0  
The push refers to repository [docker.io/suntsovvv/web-app-diploma]
a42ccfa5d1fb: Pushed 
ec492b0e5a19: Pushed 
b90d53c29dae: Mounted from library/nginx 
79bfdc61ef6f: Mounted from library/nginx 
0c95345509b7: Mounted from library/nginx 
14dc34bc60ae: Mounted from library/nginx 
45878e4d8341: Mounted from library/nginx 
9aa78b86f4b8: Mounted from library/nginx 
9853575bc4f9: Mounted from library/nginx 
1.0.0: digest: sha256:4f57d1ff57dfdb495c459dd6440e5958cdae3005eae554314c9daadfd56d079e size: 2192
```


Запустил контейнер:
```
root@astra:/home/user/testdocker# docker run -p 80:80  suntsovvv/web-app-diploma:1.0.0
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Ignoring /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh, not executable
/docker-entrypoint.sh: Ignoring /docker-entrypoint.d/15-local-resolvers.envsh, not executable
/docker-entrypoint.sh: Ignoring /docker-entrypoint.d/20-envsubst-on-templates.sh, not executable
/docker-entrypoint.sh: Ignoring /docker-entrypoint.d/30-tune-worker-processes.sh, not executable
/docker-entrypoint.sh: Configuration complete; ready for start up
2025/01/22 04:57:33 [notice] 1#1: using the "epoll" event method
2025/01/22 04:57:33 [notice] 1#1: nginx/1.27.0
2025/01/22 04:57:33 [notice] 1#1: built by gcc 12.2.0 (Debian 12.2.0-14) 
2025/01/22 04:57:33 [notice] 1#1: OS: Linux 5.15.0-70-generic
2025/01/22 04:57:33 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1048576:1048576
2025/01/22 04:57:33 [notice] 1#1: start worker processes
2025/01/22 04:57:33 [notice] 1#1: start worker process 11
2025/01/22 04:57:33 [notice] 1#1: start worker process 12
2025/01/22 04:57:33 [notice] 1#1: start worker process 13
2025/01/22 04:57:33 [notice] 1#1: start worker process 14
```
Проверяю в браузере:   
![image](https://github.com/user-attachments/assets/17d2aa20-6eda-4eec-862e-3af00c502084)


### Подготовка cистемы мониторинга и деплой приложения

Уже должны быть готовы конфигурации для автоматического создания облачной инфраструктуры и поднятия Kubernetes кластера.  
Теперь необходимо подготовить конфигурационные файлы для настройки нашего Kubernetes кластера.

Цель:
1. Задеплоить в кластер [prometheus](https://prometheus.io/), [grafana](https://grafana.com/), [alertmanager](https://github.com/prometheus/alertmanager), [экспортер](https://github.com/prometheus/node_exporter) основных метрик Kubernetes.
2. Задеплоить тестовое приложение, например, [nginx](https://www.nginx.com/) сервер отдающий статическую страницу.

Способ выполнения:
1. Воспользоваться пакетом [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus), который уже включает в себя [Kubernetes оператор](https://operatorhub.io/) для [grafana](https://grafana.com/), [prometheus](https://prometheus.io/), [alertmanager](https://github.com/prometheus/alertmanager) и [node_exporter](https://github.com/prometheus/node_exporter). Альтернативный вариант - использовать набор helm чартов от [bitnami](https://github.com/bitnami/charts/tree/main/bitnami).

2. Если на первом этапе вы не воспользовались [Terraform Cloud](https://app.terraform.io/), то задеплойте и настройте в кластере [atlantis](https://www.runatlantis.io/) для отслеживания изменений инфраструктуры. Альтернативный вариант 3 задания: вместо Terraform Cloud или atlantis настройте на автоматический запуск и применение конфигурации terraform из вашего git-репозитория в выбранной вами CI-CD системе при любом комите в main ветку. Предоставьте скриншоты работы пайплайна из CI/CD системы.

Ожидаемый результат:
1. Git репозиторий с конфигурационными файлами для настройки Kubernetes.
2. Http доступ на 80 порту к web интерфейсу grafana.
3. Дашборды в grafana отображающие состояние Kubernetes кластера.
4. Http доступ на 80 порту к тестовому приложению.

## Решение:
Доступ извне к web-интерфейсу мониторинга и приложению будет обеспечиваться по схеме балансировщик yc --> ingress ngix ---> endpoint.
Поэтому сначала устанавливаю устанавливаю ingress ngix , взял с официального сайта yaml-файл  "https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0/deploy/static/provider/cloud/deploy.yaml"   
Модифицировал его в секции сервиса, т.к. по умолчанию он устанавливается с сервисом LoadBalacer, а на самостоятельно развернутом кластере в YC такой тип балансировщика не работает.
Меняю тип сервиса на NodePort и настраиваю порт доступа. Балансировщик будет слушать порт 80 и перенаправлять траффик на NodePort.
```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    app.kubernetes.io/version: 1.12.0
  name: ingress-nginx-controller
  namespace: ingress-nginx
spec:
  externalTrafficPolicy: Local
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - appProtocol: http
    name: http
    port: 80
    protocol: TCP
    nodePort: 30080
  - appProtocol: https
    name: https
    port: 443
    protocol: TCP
    nodePort: 30443
  selector:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
  type: NodePort
```
Применяю и проверяю:
```bash
ubuntu@k8s-master:~$ kubectl apply -f nginx-ingress.yaml 
namespace/ingress-nginx created
serviceaccount/ingress-nginx created
serviceaccount/ingress-nginx-admission created
role.rbac.authorization.k8s.io/ingress-nginx created
role.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrole.rbac.authorization.k8s.io/ingress-nginx created
clusterrole.rbac.authorization.k8s.io/ingress-nginx-admission created
rolebinding.rbac.authorization.k8s.io/ingress-nginx created
rolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
configmap/ingress-nginx-controller created
service/ingress-nginx-controller created
service/ingress-nginx-controller-admission created
deployment.apps/ingress-nginx-controller created
job.batch/ingress-nginx-admission-create created
job.batch/ingress-nginx-admission-patch created
ingressclass.networking.k8s.io/nginx created
validatingwebhookconfiguration.admissionregistration.k8s.io/ingress-nginx-admission created
ubuntu@k8s-master:~$ kubectl -n ingress-nginx get all 
NAME                                           READY   STATUS      RESTARTS   AGE
pod/ingress-nginx-admission-create-t8gmf       0/1     Completed   0          82s
pod/ingress-nginx-admission-patch-5n4cg        0/1     Completed   1          82s
pod/ingress-nginx-controller-cbb88bdbc-hfnr8   1/1     Running     0          82s

NAME                                         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
service/ingress-nginx-controller             NodePort    10.108.169.184   <none>        80:30080/TCP,443:30443/TCP   82s
service/ingress-nginx-controller-admission   ClusterIP   10.101.43.156    <none>        443/TCP                      82s

NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/ingress-nginx-controller   1/1     1            1           82s

NAME                                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/ingress-nginx-controller-cbb88bdbc   1         1         1       82s

NAME                                       STATUS     COMPLETIONS   DURATION   AGE
job.batch/ingress-nginx-admission-create   Complete   1/1           8s         82s
job.batch/ingress-nginx-admission-patch    Complete   1/1           10s        82s
```
Для мониторинга буду использовать пакет [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus)   
Клонирую репозиторий на master-ноду:   
```bash
ubuntu@k8s-master:~$ git clone https://github.com/prometheus-operator/kube-prometheus.git
Cloning into 'kube-prometheus'...
remote: Enumerating objects: 20747, done.
remote: Counting objects: 100% (5295/5295), done.
remote: Compressing objects: 100% (283/283), done.
remote: Total 20747 (delta 5164), reused 5020 (delta 5010), pack-reused 15452 (from 2)
Receiving objects: 100% (20747/20747), 12.99 MiB | 20.49 MiB/s, done.
Resolving deltas: 100% (14355/14355), done.
```
Далее для того чтобы web-интерфейс Grafana работал через ингресс, необходимо выполнить правки в манифестах.   
grafana-config:
```yaml
apiVersion: v1
kind: Secret
metadata:
  labels:
    app.kubernetes.io/component: grafana
    app.kubernetes.io/name: grafana
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 11.4.0
  name: grafana-config
  namespace: monitoring
stringData:
  grafana.ini: |
    [date_formats]
    default_timezone = UTC
    [server]
    root_url = http://suntsovvv.ru/grafana
type: Opaque
```
Данный код необходим, чтобы корректно происходил редирект при использовании ингресса. Указал dns имя по которому будут приходить запросы. Данная настройка актуальна для  Grafana версии выше 10.0.0
```
    [server]
    root_url = http://suntsovvv.ru/grafana
```
Так же необходимо поправить манифест grafana-networkPolicy.yaml чтобы разрешить входящий траффик: 
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  labels:
    app.kubernetes.io/component: grafana
    app.kubernetes.io/name: grafana
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 11.4.0
  name: grafana
  namespace: monitoring
spec:
  egress:
  - {}
  ingress:
  - {}
  policyTypes:
  - Egress
  - Ingress
```
Выполняю установку системы мониторинг и проверяю:
```bash
ubuntu@k8s-master:~/kube-prometheus$ kubectl apply --server-side -f manifests/setup
kubectl wait \
        --for condition=Established \
        --all CustomResourceDefinition \
        --namespace=monitoring
kubectl apply -f manifests/
..................................................................
ubuntu@k8s-master:~/kube-prometheus$ kubectl -n monitoring get all
NAME                                      READY   STATUS    RESTARTS   AGE
pod/alertmanager-main-0                   2/2     Running   0          70s
pod/alertmanager-main-1                   2/2     Running   0          70s
pod/alertmanager-main-2                   2/2     Running   0          70s
pod/blackbox-exporter-649ff58c4f-rhsjj    3/3     Running   0          106s
pod/grafana-68674dbd6-xv7sq               1/1     Running   0          105s
pod/kube-state-metrics-65f74b9b4d-p7kvh   3/3     Running   0          105s
pod/node-exporter-fp56x                   2/2     Running   0          105s
pod/node-exporter-r2xvv                   2/2     Running   0          105s
pod/node-exporter-v7sxv                   2/2     Running   0          105s
pod/prometheus-adapter-5794d7d9f5-f5b2q   1/1     Running   0          104s
pod/prometheus-adapter-5794d7d9f5-qrs9z   1/1     Running   0          104s
pod/prometheus-k8s-0                      2/2     Running   0          70s
pod/prometheus-k8s-1                      2/2     Running   0          70s
pod/prometheus-operator-d84db789b-fb225   2/2     Running   0          104s

NAME                            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
service/alertmanager-main       ClusterIP   10.105.29.188    <none>        9093/TCP,8080/TCP            106s
service/alertmanager-operated   ClusterIP   None             <none>        9093/TCP,9094/TCP,9094/UDP   71s
service/blackbox-exporter       ClusterIP   10.97.20.87      <none>        9115/TCP,19115/TCP           106s
service/grafana                 ClusterIP   10.107.62.189    <none>        3000/TCP                     105s
service/kube-state-metrics      ClusterIP   None             <none>        8443/TCP,9443/TCP            105s
service/node-exporter           ClusterIP   None             <none>        9100/TCP                     105s
service/prometheus-adapter      ClusterIP   10.106.44.218    <none>        443/TCP                      104s
service/prometheus-k8s          ClusterIP   10.100.242.189   <none>        9090/TCP,8080/TCP            104s
service/prometheus-operated     ClusterIP   None             <none>        9090/TCP                     70s
service/prometheus-operator     ClusterIP   None             <none>        8443/TCP                     104s

NAME                           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/node-exporter   3         3         3       3            3           kubernetes.io/os=linux   105s

NAME                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/blackbox-exporter     1/1     1            1           106s
deployment.apps/grafana               1/1     1            1           105s
deployment.apps/kube-state-metrics    1/1     1            1           105s
deployment.apps/prometheus-adapter    2/2     2            2           104s
deployment.apps/prometheus-operator   1/1     1            1           104s

NAME                                            DESIRED   CURRENT   READY   AGE
replicaset.apps/blackbox-exporter-649ff58c4f    1         1         1       106s
replicaset.apps/grafana-68674dbd6               1         1         1       105s
replicaset.apps/kube-state-metrics-65f74b9b4d   1         1         1       105s
replicaset.apps/prometheus-adapter-5794d7d9f5   2         2         2       104s
replicaset.apps/prometheus-operator-d84db789b   1         1         1       104s

NAME                                 READY   AGE
statefulset.apps/alertmanager-main   3/3     70s
statefulset.apps/prometheus-k8s      2/2     70s
```
Теперь необходимо создать балансировщик и ingress для доступа извне к веб интерфейсу графана.
Дополняю конфигурацию terraform :
```hcl
# Создание групп целей для балансировщика нагрузки
resource "yandex_lb_target_group" "k8s-cluster" {
  name = "k8s-cluster"
  target {
    subnet_id = yandex_vpc_subnet.ru-central1-a.id
    address   = yandex_compute_instance.worker-1.network_interface[0].ip_address
  }
  target {
    subnet_id = yandex_vpc_subnet.ru-central1-b.id
    address   = yandex_compute_instance.worker-2.network_interface[0].ip_address
  }
 }

#Создание сетевого балансировщика

resource "yandex_lb_network_load_balancer" "k8s" {
  name = "k8s-balancer"

  listener {
    name = "${ var.listener_web_app.name }"
    port = var.listener_web_app.port
    target_port = var.listener_web_app.target_port

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.k8s-cluster.id
    healthcheck {
      name = "tcp"
      tcp_options {
        port = 22

      }
    }
  }
}
```
Так же доработал output , чтобы выводились внешние ip и порт балансировщика:
```
Outputs:

all_vms = {
  "bastion-nat" = [
    {
      "name" = "bastion-nat"
      "nat_ip_address" = "89.169.139.110"
    },
  ]
  "master" = [
    {
      "ip_address" = "10.10.1.24"
      "name" = "k8s-master"
    },
  ]
}
listener_sockets = [
  {
    "address" = "158.160.133.135"
    "name" = "web-app"
    "port" = 80
  },
]
```
![image](https://github.com/user-attachments/assets/202fe643-389f-46c8-8c01-94dcbaa7e4b2)
Пишу манифест ingress для grafana:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: monitoring-ingress
  namespace: monitoring
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: suntsovvv.ru
    http:
      paths:
      - path: /grafana
        pathType: Prefix
        backend:
          service:
            name: grafana
            port:
              number: 3000
```
Применяю и проверяю через web, для проверки добавил в запись в hosts файл машины ( <ip балансирщка>  suntsovvv.ru)   
Web-интерфейс Grafana доступен на 80-м порту по адресу http://suntsovvv.ru/grafana/

![image](https://github.com/user-attachments/assets/7fe5037b-1c18-40d5-a712-1011fdc6e46f)   
Теперь выполню деплой моего тестового приложения, для жтого создыб манифест:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-diploma
  namespace: web-app-diploma
  labels:
    app: web-app-diploma
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app-diploma
  template:
    metadata:
      labels:
        app: web-app-diploma
    spec:
      containers:
      - name: web-app-diploma
        image: suntsovvv/web-app-diploma:1.0.0
        ports:
        - containerPort: 80

---
apiVersion: v1
kind: Service
metadata:
  name: web-app-diploma
  namespace: web-app-diploma
spec:
  type: NodePort
  selector:
    app: web-app-diploma
  ports:
    - protocol: TCP
      name: web-app-diploma
      port: 80
      nodePort: 31080
---
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: web-app-diploma
  namespace: web-app-diploma
spec:
  podSelector:
    matchLabels:
      app: web-app-diploma
  ingress:
  - {}
```
Создаю namespace и применяю:   
```bash
ubuntu@k8s-master:~$ kubectl create namespace web-app-diploma
namespace/web-app-diploma created
ubuntu@k8s-master:~$ kubectl apply -f web-app-diploma.yaml 
deployment.apps/web-app-diploma created
service/web-app-diploma created
networkpolicy.networking.k8s.io/web-app-diploma created
ubuntu@k8s-master:~$ kubectl -n web-app-diploma get all
NAME                                   READY   STATUS    RESTARTS   AGE
pod/web-app-diploma-55fd8c8b5d-2ccp6   1/1     Running   0          34s
pod/web-app-diploma-55fd8c8b5d-6nfnz   1/1     Running   0          34s
pod/web-app-diploma-55fd8c8b5d-lvrvf   1/1     Running   0          34s

NAME                      TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
service/web-app-diploma   NodePort   10.103.51.135   <none>        80:31080/TCP   34s

NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web-app-diploma   3/3     3            3           34s

NAME                                         DESIRED   CURRENT   READY   AGE
replicaset.apps/web-app-diploma-55fd8c8b5d   3         3         3       34s
```
Осталось написать ingress для web-приложения:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  namespace: web-app-diploma
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: suntsovvv.ru
    http:
      paths:
      - path: /web
        pathType: Prefix
        backend:
          service:
            name: web-app-diploma
            port:
              number: 80
```
Применяю и проверяю:
```bash
ubuntu@k8s-master:~$ kubectl apply -f web-ingress.yaml 
ingress.networking.k8s.io/web-ingress created
```
Тестовое приложение доступено на 80-м порту по адресу http://suntsovvv.ru/web
![image](https://github.com/user-attachments/assets/22bd21b0-a1d5-4901-80a1-02111e027c33)


Проверяю сервисы которые поднялись и смотрю поты:
```bash
ubuntu@k8s-master:~/kube-prometheus$ kubectl -n monitoring get svc
NAME                    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
alertmanager-main       ClusterIP   10.100.109.197   <none>        9093/TCP,8080/TCP            5m56s
alertmanager-operated   ClusterIP   None             <none>        9093/TCP,9094/TCP,9094/UDP   5m16s
blackbox-exporter       ClusterIP   10.102.49.27     <none>        9115/TCP,19115/TCP           5m56s
grafana                 ClusterIP   10.111.113.146   <none>        3000/TCP                     5m55s
kube-state-metrics      ClusterIP   None             <none>        8443/TCP,9443/TCP            5m55s
node-exporter           ClusterIP   None             <none>        9100/TCP                     5m55s
prometheus-adapter      ClusterIP   10.105.103.52    <none>        443/TCP                      5m54s
prometheus-k8s          ClusterIP   10.106.14.3      <none>        9090/TCP,8080/TCP            5m55s
prometheus-operated     ClusterIP   None             <none>        9090/TCP                     5m15s
prometheus-operator     ClusterIP   None             <none>        8443/TCP                     5m54s
```
Для  чтобы был доступ к web-интерфейсу grafana, меняю тип сервиса на nodePort создаю политику:
```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/name: grafana-service
  name: grafana
  namespace: monitoring
spec:
  type: NodePort
  ports:
  - name: grafana-port
    port: 3000
    targetPort: 3000
    nodePort: 31300
  selector:
    app.kubernetes.io/component: grafana
    app.kubernetes.io/name: grafana
    app.kubernetes.io/part-of: kube-prometheus

---
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: grafana
spec:
  podSelector:
    matchLabels:
      app: grafana
  ingress:
  - {}

```
Применяю и проверяю сервисы:
```bash
ubuntu@k8s-master:~$ kubectl apply -f grafana.yaml 
service/grafana configured
networkpolicy.networking.k8s.io/grafana configured
ubuntu@k8s-master:~$ kubectl -n monitoring get svc
NAME                    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
alertmanager-main       ClusterIP   10.100.109.197   <none>        9093/TCP,8080/TCP            28m
alertmanager-operated   ClusterIP   None             <none>        9093/TCP,9094/TCP,9094/UDP   28m
blackbox-exporter       ClusterIP   10.102.49.27     <none>        9115/TCP,19115/TCP           28m
grafana                 NodePort    10.111.113.146   <none>        3000:31300/TCP               28m
kube-state-metrics      ClusterIP   None             <none>        8443/TCP,9443/TCP            28m
node-exporter           ClusterIP   None             <none>        9100/TCP                     28m
prometheus-adapter      ClusterIP   10.105.103.52    <none>        443/TCP                      28m
prometheus-k8s          ClusterIP   10.106.14.3      <none>        9090/TCP,8080/TCP            28m
prometheus-operated     ClusterIP   None             <none>        9090/TCP                     28m
prometheus-operator     ClusterIP   None             <none>        8443/TCP                     28m
```
Cоздаю балансировщик и листенер:
```yaml
# Создание групп целей для балансировщика нагрузки
resource "yandex_lb_target_group" "k8s-cluster" {
  name = "k8s-cluster"
  target {
    subnet_id = yandex_vpc_subnet.ru-central1-a.id
    address   = yandex_compute_instance.worker-1.network_interface[0].ip_address
  }
  target {
    subnet_id = yandex_vpc_subnet.ru-central1-b.id
    address   = yandex_compute_instance.worker-2.network_interface[0].ip_address
  }
 
}

#Создание сетевого балансировщика

resource "yandex_lb_network_load_balancer" "k8s" {
  name = "k8s-balancer"

  listener {
    name = "${ var.listener_grafana.name }"
    port = var.listener_grafana.port
    target_port = var.listener_grafana.target_port

    external_address_spec {
      ip_version = "ipv4"
    }
  }


  attached_target_group {
    target_group_id = yandex_lb_target_group.k8s-cluster.id
    healthcheck {
      name = "tcp"
      tcp_options {
        port = var.listener_grafana.target_port

      }
    }
  }
}

```
Применяю и проверяю доступ через web:
![image](https://github.com/user-attachments/assets/59705e9f-e197-407a-a8e0-6fdea3eccbd4)   
![image](https://github.com/user-attachments/assets/b784062f-887c-4388-9eb5-184727eca030)
Теперь можно




---
### Установка и настройка CI/CD

Осталось настроить ci/cd систему для автоматической сборки docker image и деплоя приложения при изменении кода.

Цель:

1. Автоматическая сборка docker образа при коммите в репозиторий с тестовым приложением.
2. Автоматический деплой нового docker образа.

Можно использовать [teamcity](https://www.jetbrains.com/ru-ru/teamcity/), [jenkins](https://www.jenkins.io/), [GitLab CI](https://about.gitlab.com/stages-devops-lifecycle/continuous-integration/) или GitHub Actions.

Ожидаемый результат:

1. Интерфейс ci/cd сервиса доступен по http.
2. При любом коммите в репозиторие с тестовым приложением происходит сборка и отправка в регистр Docker образа.
3. При создании тега (например, v1.0.0) происходит сборка и отправка с соответствующим label в регистри, а также деплой соответствующего Docker образа в кластер Kubernetes.

---
## Что необходимо для сдачи задания?

1. Репозиторий с конфигурационными файлами Terraform и готовность продемонстрировать создание всех ресурсов с нуля.
2. Пример pull request с комментариями созданными atlantis'ом или снимки экрана из Terraform Cloud или вашего CI-CD-terraform pipeline.
3. Репозиторий с конфигурацией ansible, если был выбран способ создания Kubernetes кластера при помощи ansible.
4. Репозиторий с Dockerfile тестового приложения и ссылка на собранный docker image.
5. Репозиторий с конфигурацией Kubernetes кластера.
6. Ссылка на тестовое приложение и веб интерфейс Grafana с данными доступа.
7. Все репозитории рекомендуется хранить на одном ресурсе (github, gitlab)
