
resource "yandex_compute_instance" "master" {
  # count = var.master.count
  # name        = "k8s-master-${count.index}"
  # zone = "${var.subnet_zone[count.index]}"
  # platform_id = var.master.platform_id
  # hostname = "k8s-master-${count.index}"
  name        = "k8s-master"
  zone = "${var.subnet_zone[0]}"
  platform_id = var.master.platform_id
  hostname = "k8s-master"
  allow_stopping_for_update = true


  resources {
    cores         = var.master.cores
    memory        = var.master.memory
    core_fraction = var.master.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 40
    }
  }

## Прерываемая
  scheduling_policy {
    preemptible = true
  }


  network_interface {
    subnet_id = yandex_vpc_subnet.ru-central1-a.id
    security_group_ids = [yandex_vpc_security_group.nat-instance-sg.id]
#    nat       = true
  }

  metadata = {
    serial-port-enable = 1
    ssh-keys  = "ubuntu:${file(var.ssh_public_key_path)}"
    }
  }

 
 resource "yandex_compute_instance" "worker-1" {
  name        = "k8s-worker-1"
  zone = "${var.subnet_zone[0]}"
  platform_id = var.worker.platform_id
  hostname = "k8s-worker-1"
  allow_stopping_for_update = true
  

  resources {
    cores         = var.worker.cores
    memory        = var.worker.memory
    core_fraction = var.worker.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 40
    }
  }
## Прерываемая
  scheduling_policy {
    preemptible = true
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.ru-central1-a.id
    security_group_ids = [yandex_vpc_security_group.nat-instance-sg.id]
#    nat       = true
  }

  metadata = {
    serial-port-enable = 1
    ssh-keys  = "ubuntu:${file(var.ssh_public_key_path)}"
    
  }
  

 }

 resource "yandex_compute_instance" "worker-2" {
  name        = "k8s-worker-2"
  zone = "${var.subnet_zone[1]}"
  platform_id = var.worker.platform_id
  hostname = "k8s-worker-2"
  allow_stopping_for_update = true
  

  resources {
    cores         = var.worker.cores
    memory        = var.worker.memory
    core_fraction = var.worker.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 40
    }
  }
## Прерываемая
  scheduling_policy {
    preemptible = true
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.ru-central1-b.id
    security_group_ids = [yandex_vpc_security_group.nat-instance-sg.id]
#    nat       = true
  }

  metadata = {
    serial-port-enable = 1
    ssh-keys  = "ubuntu:${file(var.ssh_public_key_path)}"
    
  }
  

 }
 resource "yandex_compute_instance" "bastion-nat" {
  
  name = "bastion-nat"
  allow_stopping_for_update = true
    resources {
    cores  = var.bastion.cores
    memory = var.bastion.memory
    core_fraction = var.bastion.core_fraction
    
    }
    scheduling_policy {
    preemptible = true
    
    }
    boot_disk {

    initialize_params {
      image_id = "fd8m30o437b5c6b9en6r"
      size = 20
    }
    
    }
    network_interface {

    subnet_id          = yandex_vpc_subnet.bastion-nat.id
    security_group_ids = [yandex_vpc_security_group.nat-instance-sg.id]
    nat                = true
    }
    metadata = {
      serial-port-enable = 1
      ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}