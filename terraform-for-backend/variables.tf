
variable "cloud_id" {
  description = "ID облака"
  type        = string
}

variable "folder_id" {
  description = "ID папки"
  type        = string
}

variable "zone" {
  description = "Зона доступности"
  type        = string
}

variable "token" {
  type        = string
  description = "Переменная в  которой хранится токен доступа к аккаунту"
  sensitive = true
  }