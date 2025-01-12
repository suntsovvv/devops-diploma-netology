# terraform {
#  backend "s3" {
#        endpoints = {
#       s3 = "https://storage.yandexcloud.net"
#      }
#     bucket = "bucket-suntsovvv-2025"
#     region = "ru-central1"
#     key    = "terraform.tfstate"
#     access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
#     secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key

#     skip_region_validation      = true
#     skip_credentials_validation = true
#     skip_requesting_account_id  = true # Необходимая опция Terraform для версии 1.6.1 и старше.
#     skip_s3_checksum            = true # Необходимая опция при описании бэкенда для Terraform версии 1.6.3 и старше.
#   }
# }

# resource "yandex_storage_object" "state-file" {
#     access_key = "${yandex_iam_service_account_static_access_key.sa-static-key.access_key}"
#     secret_key = "${yandex_iam_service_account_static_access_key.sa-static-key.secret_key}"
#     bucket = yandex_storage_bucket.tstate
#     key = "terraform.tfstate"
#     source = "./terraform.tfstate"
#     acl    = "private"
#     depends_on = [yandex_storage_bucket.tstate]
# }