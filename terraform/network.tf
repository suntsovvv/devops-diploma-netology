resource "yandex_vpc_network" "k8s" {
  name = var.vpc_name
}
# resource "yandex_vpc_subnet" "subnet_zones" {
#   count          = 3
#   name           = "subnet-${var.subnet_zone[count.index]}"
#   zone           = "${var.subnet_zone[count.index]}"
#   network_id     = "${yandex_vpc_network.k8s.id}"
#   route_table_id = yandex_vpc_route_table.nat-instance-route.id
#   v4_cidr_blocks = [ "${var.cidr[count.index]}" ]
# }
# Создание подсетей
resource "yandex_vpc_subnet" "ru-central1-a" {
  zone           = var.subnet_zone[0]
  name = "ru-central1-a"
  network_id     = "${yandex_vpc_network.k8s.id}"
  v4_cidr_blocks = ["${var.cidr[0]}"]
  route_table_id = yandex_vpc_route_table.nat-instance-route.id

}
resource "yandex_vpc_subnet" "ru-central1-b" {
  zone           = var.subnet_zone[1]
  name = "ru-central1-b"
  network_id     = "${yandex_vpc_network.k8s.id}"
  v4_cidr_blocks = ["${var.cidr[1]}"]
  route_table_id = yandex_vpc_route_table.nat-instance-route.id

}

resource "yandex_vpc_subnet" "ru-central1-d" {
  zone           = var.subnet_zone[2]
  name = "ru-central1-d"
  network_id     = "${yandex_vpc_network.k8s.id}"
  v4_cidr_blocks = ["${var.cidr[2]}"]
  route_table_id = yandex_vpc_route_table.nat-instance-route.id
}
resource "yandex_vpc_subnet" "bastion-nat" {
  zone           = var.subnet_zone[0]
  name = "k8s-out"
  network_id     = "${yandex_vpc_network.k8s.id}"
  v4_cidr_blocks = ["${var.cidr[3]}"]

}
# Создание таблицы маршрутизации и статического маршрута

resource "yandex_vpc_route_table" "nat-instance-route" {
  name       = "nat-instance-route"
  network_id = "${yandex_vpc_network.k8s.id}"
  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = yandex_compute_instance.bastion-nat.network_interface.0.ip_address
  }
}

resource "yandex_vpc_security_group" "nat-instance-sg" {
  name       = "nat-instance-sg"
  network_id = yandex_vpc_network.k8s.id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Создание групп целей для балансировщика нагрузки
resource "yandex_lb_target_group" "k8s-cluster" {
  name = "k8s-cluster"
  target {
    subnet_id = yandex_vpc_subnet.ru-central1-a.id
    address   = yandex_compute_instance.worker-1.network_interface[0].ip_address
  }
  target {
    subnet_id = yandex_vpc_subnet.ru-central1-b.id
    address   = yandex_compute_instance.worker-2.network_interface[0].ip_address
  }
 
}
resource "yandex_lb_target_group" "kubectl" {
  name = "kubectl"
  target {
    subnet_id = yandex_vpc_subnet.ru-central1-a.id
    address   = yandex_compute_instance.master.network_interface[0].ip_address
  }

}


#Создание сетевого балансировщика

resource "yandex_lb_network_load_balancer" "k8s" {
  name = "k8s-balancer"

  listener {
    name = "web-app"
    port = 80
    target_port = 31080

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  listener {
    name = "grafana"
    port = 3000
    target_port = 30001

    external_address_spec {
      ip_version = "ipv4"
    }
  }


  attached_target_group {
    target_group_id = yandex_lb_target_group.k8s-cluster.id
    healthcheck {
      name = "tcp"
      tcp_options {
        port = 30080

      }
    }
  }
  attached_target_group {
    target_group_id = yandex_lb_target_group.kubectl.id
    healthcheck {
      name = "tcp"
      tcp_options {
        port = 30001

      }
    }
  }
}














