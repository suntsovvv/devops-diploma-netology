
variable "cloud_id" {
  description = "ID облака"
  type        = string
  default = "b1g6dgftb02k9esf1nmu"
}

variable "folder_id" {
  description = "ID папки"
  type        = string
  default = "b1gpta86451pk7tseq2b"
}

variable "zone" {
  description = "Зона доступности"
  type        = string
  default     = "ru-central1-a"
}

variable "token" {
  type        = string
  description = "Переменная в  которой хранится токен доступа к аккаунту"
  sensitive = true
  }