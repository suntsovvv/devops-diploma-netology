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
              
      }]
    # ],

    # worker = [
    #       for instance in yandex_compute_instance.worker-1: {
    #     name = instance.name
    #     ip_address = instance.network_interface[0].ip_address       
    #     }
    #     ]
         
}
}
# output "nested_output" {
#   value = {
#     for group in var.outer_list : 
#     group.name => [
#       for value in group.values : 
#       "${group.name}-${value}"
#     ]
#   }
# }