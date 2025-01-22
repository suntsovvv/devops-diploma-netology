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
resource "yandex_vpc_network" "develop" {
  name = var.vpc_name
}
resource "yandex_vpc_subnet" "subnet_zones" {
  count          = 3
  name           = "subnet-${var.subnet_zone[count.index]}"
  zone           = "${var.subnet_zone[count.index]}"
  network_id     = "${yandex_vpc_network.develop.id}"
  v4_cidr_blocks = [ "${var.cidr[count.index]}" ]
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
![image](https://github.com/user-attachments/assets/46d9e0fd-d4b3-42e1-a634-730a9efd4d76)

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
