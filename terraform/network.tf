resource "yandex_vpc_network" "k8s" {
  name = var.vpc_name
}

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















