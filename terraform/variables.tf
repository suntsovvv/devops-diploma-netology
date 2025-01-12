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


variable "service_account_key_file" {
  description = "Путь к файлу ключа сервисного аккаунта"
  type        = string
  default     = "~/key.json"
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
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}

variable "cidr" {
  type        = list(string)
  default     = ["10.10.1.0/24","10.10.2.0/24","10.10.3.0/24"]
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}

variable "ubuntu-2204-lts" {
  default = "fd83prfqnldo1u6hvmmg"
}

# variable "subnet_public_name" {
#   description = "Имя публичной подсети"
#   type        = string
#   default     = "public"
# }

# variable "subnet_private_name" {
#   description = "Имя приватной подсети"
#   type        = string
#   default     = "private"
# }

# ###cloud vars

## Переменная для token
variable "token" {
  type        = string
  description = "OAuth-token; https://cloud.yandex.ru/docs/iam/concepts/authorization/oauth-token"
  default = ""
}

# ## Переменная для cloud_id
# variable "cloud_id" {
#   type        = string
#   description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
# }





# ## Переменная для vpc_name
# variable "vpc_name" {
#   type        = string
#   default     = "develop"
#   description = "VPC network&subnet name"
# }

# ## Переменная для public_key
# variable "public_key" {
#   type    = string
#   default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIS4+FPnsV5rzJWre6TQCpd9mUMTq0Y0NoBEwVpD06PpCLFMwAYB2Ot916ZOTctE6DqsfXmayVQp9gs/pJ+1XQ4CyqQ0IVeIxJGo9F6YMbuCahBNe186I/ampcmFmeyWmakTDSGD6rf4ABZK+GM+hcKdgnQTddmji21fyCxwQP9CoU5ifBbjWUzIu9ZTYLFUoJnkaRzYJ2ZN8ZGNUEGObDG/EboMUkH4VQfFzrmhQa7xfNQn4MuHKK7hsTNCozU6W2nm9BOLzJfC2W8TnsKFwdxPG6e4CTkTSE9RbmR68AXc1I4VBx+e30T7XIn7OIB9njRIPX8ctEKPSBez1dFwEz49Qjn2/MJpQzXS09ZsLBPJSd55RGS9bhfp+1tIqh1vFWYsJCGALe1/nvGiasfGGkQuuW+Zx74p4fjKtHIT/vDrXpn6aTwmCZPQGysfodLOfewcQjPVuwIYn2vqMk7FvABvXa3mak/owvpYDhYWtlSA7OExlSblf1bKUepEvoGEU= nicolay@nicolay-VirtualBox"
# }


