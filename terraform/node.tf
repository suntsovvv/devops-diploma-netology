
resource "yandex_compute_instance" "master" {
  count = var.master.count
  name        = "k8s-master-${count.index}"
  zone = "${var.subnet_zone[count.index]}"
  platform_id = var.master.platform_id
  hostname = "k8s-master-${count.index}"
  
  allow_stopping_for_update = true


  resources {
    cores         = var.master.cores
    memory        = var.master.memory
    core_fraction = var.master.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 60
    }
  }

## Прерываемая
  scheduling_policy {
    preemptible = true
  }


  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet_zones[count.index].id}"
    nat       = true
  }

  metadata = {
    serial-port-enable = 1
    ssh-keys  = "ubuntu:${file(var.ssh_public_key_path)}"
    }
  }

 
 resource "yandex_compute_instance" "worker" {
  count = var.worker.count
  name        = "k8s-worker-${count.index}"
  zone = "${var.subnet_zone[count.index]}"
  platform_id = var.master.platform_id
  hostname = "k8s-worker-${count.index}"
  
  allow_stopping_for_update = true


  resources {
    cores         = var.worker.cores
    memory        = var.worker.memory
    core_fraction = var.worker.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 60
    }
  }

## Прерываемая
  scheduling_policy {
    preemptible = true
  }


  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet_zones[count.index].id}"
    nat       = true
  }

  metadata = {
    serial-port-enable = 1
    ssh-keys  = "ubuntu:${file(var.ssh_public_key_path)}"
    
  }
  

 }

