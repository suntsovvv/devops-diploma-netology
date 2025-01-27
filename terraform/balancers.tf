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
# resource "yandex_lb_target_group" "kubectl" {
#   name = "kubectl"
#   target {
#     subnet_id = yandex_vpc_subnet.ru-central1-a.id
#     address   = yandex_compute_instance.master.network_interface[0].ip_address
#   }

# }

#Создание сетевого балансировщика

resource "yandex_lb_network_load_balancer" "k8s" {
  name = "k8s-balancer"

  listener {
    name = "${ var.listener_web_app.name }"
    port = var.listener_web_app.port
    target_port = var.listener_web_app.target_port

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  listener {
    name = "${ var.listener_grafana.name }"
    port = var.listener_grafana.port
    target_port = var.listener_grafana.target_port

    external_address_spec {
      ip_version = "ipv4"
    }
  }


  attached_target_group {
    target_group_id = yandex_lb_target_group.k8s-cluster.id
    healthcheck {
      name = "tcp"
      tcp_options {
        port = var.listener_web_app.target_port

      }
    }
  }
#   attached_target_group {
#     target_group_id = yandex_lb_target_group.kubectl.id
#     healthcheck {
#       name = "tcp"
#       tcp_options {
#         port = 30001

#       }
#     }
#   }
}
