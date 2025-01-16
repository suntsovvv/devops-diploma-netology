resource "local_file" "hosts_cfg_kubespray" {
#  count = var.exclude_ansible ? 0 : 1
  content = templatefile("inventory.tftpl",
    { 
      masters = yandex_compute_instance.master
      workers = yandex_compute_instance.worker
    })

  filename = "../ansible/hosts.yaml"
}