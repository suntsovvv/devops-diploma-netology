output "all_vms" {
  description = "Information about the instances"
  value = {
    bastion-nat = [
         {  name = yandex_compute_instance.bastion-nat.name
            nat_ip_address = yandex_compute_instance.bastion-nat.network_interface[0].nat_ip_address
        }
        ],    
    master = [
       {
        name = yandex_compute_instance.master.name
        ip_address = yandex_compute_instance.master.network_interface[0].ip_address
              
      }],
  
  

 balancer_external_ip = [for lb in yandex_lb_network_load_balancer.k8s.listener : lb.name ]

        
}

}
output "listener_ip_addresses" {
value = {
    
      for listener in yandex_lb_network_load_balancer.k8s.listener :
      listener.name => [ for spec in listener.external_address_spec : spec.address
      ]
    }
}
