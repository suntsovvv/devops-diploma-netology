resource "local_file" "hosts_cfg" {
#  count = var.exclude_ansible ? 0 : 1
  content = templatefile("inventory.tftpl",
    { 
      k8s-masters = yandex_compute_instance.master
      k8s-workers = yandex_compute_instance.worker
    })

  filename = "../ansible/hosts.yaml"
}
