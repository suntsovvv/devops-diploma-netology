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
variable "token" {
  type        = string
  description = "Переменная в  которой хранится токен доступа к аккаунту"
  sensitive = true
  }

variable "zone" {
  description = "Зона доступности"
  type        = string
  default     = "ru-central1-a"
}

variable "ssh_public_key_path" {
  description = "Путь к публичному SSH ключу"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "vpc_name" {
  description = "Имя виртуальной сети k8s"
  type        = string
  default     = "VPC-k8s"
}

variable "subnet_zone" {
  type        = list(string)
  default     = ["ru-central1-a","ru-central1-b","ru-central1-d"]
  description = "Список зон"
}

variable "cidr" {
  type        = list(string)
  default     = ["10.10.1.0/24","10.10.2.0/24","10.10.3.0/24"]
  description = "Список CIDR-ов"
}

variable "ubuntu-2204-lts" {
  default = "fd83prfqnldo1u6hvmmg"
  description = "ID образа ОС"
}

