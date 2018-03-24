output "IP_Addresses" {
  value = <<CONFIGURATION

Client public IPs: ${join(", ", module.nomadconsul.client_public_ips)}
Client private IPs: ${join(", ", module.nomadconsul.client_private_ips)}
Server public IPs: ${join(", ", module.nomadconsul.primary_server_public_ips)}
Server private IPs: ${join(", ", module.nomadconsul.primary_server_private_ips)}

To connect, add your private key and SSH into any client or server with
`ssh -i "${var.key_name}.pem" ubuntu@${element(module.nomadconsul.primary_server_public_ips, 0)}`. You can test the integrity of the cluster by running:

  $ consul members
  $ nomad server-members
  $ nomad node-status

If you see an error message like the following when running any of the above
commands, it usuallly indicates that the configuration script has not finished
executing:

"Error querying servers: Get http://127.0.0.1:4646/v1/agent/members: dial tcp
127.0.0.1:4646: getsockopt: connection refused"

Simply wait a few seconds and rerun the command if this occurs.

The Consul UI can be accessed at http://${element(module.nomadconsul.primary_server_public_ips, 0)}:8500/ui.

The Nomad UI can be accessed at http://${element(module.nomadconsul.primary_server_public_ips, 0)}:4646/ui.

CONFIGURATION
}
