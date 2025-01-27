
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
      image_id = var.master.image_id
      size     = var.master.disk_sze
    }
  }


  scheduling_policy {
    preemptible = var.master.scheduling_policy
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
      image_id = var.worker.image_id
      size     = var.worker.disk_sze
    }
  }
## Прерываемая
  scheduling_policy {
    preemptible = var.worker.scheduling_policy
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
      image_id = var.worker.image_id
      size     = var.worker.disk_sze
    }
  }
## Прерываемая
  scheduling_policy {
    preemptible = var.bastion.scheduling_policy
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
    preemptible = var.bastion.scheduling_policy
    
    }
    boot_disk {

    initialize_params {
      image_id = var.bastion.image_id
      size = var.bastion.disk_sze
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