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

}
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


