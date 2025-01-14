
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

variable "ssh_public_key_path" {
  description = "Путь к публичному SSH ключу"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "vpc_name" {
  description = "Имя виртуальной сети k8s"
  type        = string
}

variable "subnet_zone" {
  type        = list(string)
  description = "Список зон"
}

variable "cidr" {
  type        = list(string)
  description = "Список CIDR-ов"
}

variable "ubuntu-2204-lts" {
  description = "ID образа ОС"
}

