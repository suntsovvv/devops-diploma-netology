resource "yandex_iam_service_account" "sa" {
  name = "sa-for-bucket"
}

# Назначение роли сервисному аккаунту
resource "yandex_resourcemanager_folder_iam_member" "sa-editor" {
  folder_id = var.folder_id
  role      = "editor"
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
# 
  # provisioner "local-exec" {
  # command = "export ACCESS_KEY=${yandex_iam_service_account_static_access_key.sa-static-key.access_key} "
  # }

  # provisioner "local-exec" {
  # command = "export SECRET_KEY=${yandex_iam_service_account_static_access_key.sa-static-key.secret_key} "
  # }
  #  provisioner "local-exec" {
  # command = "echo export ACCESS_KEY=${yandex_iam_service_account_static_access_key.sa-static-key.access_key} > ../terraform/secret.backend.auto.tfvars"
  # }

  # provisioner "local-exec" {
  # command = "echo export SECRET_KEY=${yandex_iam_service_account_static_access_key.sa-static-key.secret_key} >> ../terraform/secret.backend.auto.tfvars"
  # }
}
resource "local_file" "backend" {
  content  = <<EOT

bucket = "${yandex_storage_bucket.tstate.bucket}"
region = "ru-central1"
key = "terraform.tfstate"
access_key = "${yandex_iam_service_account_static_access_key.sa-static-key.access_key}"
secret_key = "${yandex_iam_service_account_static_access_key.sa-static-key.secret_key}"
skip_region_validation = true
skip_credentials_validation = true
EOT
  filename = "../terraform/secret.backend.tfvars"

}


