
resource "yandex_compute_instance" "platform" {
  count = 3
  name        = "node-${count.index}"
  zone = "${var.subnet_zone[count.index]}"
  platform_id = "standard-v3"
  hostname = "node-${count.index}"
  allow_stopping_for_update = true


  resources {
    cores         = 4
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.ubuntu-2204-lts
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
    ssh-keys  = "ubuntu:${var.ssh_public_key_path}"
  }

}
