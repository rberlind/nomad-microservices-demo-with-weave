data_dir = "/opt/nomad/data"
bind_addr = "0.0.0.0"
name = "nomad@IP_ADDRESS"

# Enable the client
client {
  enabled = true
  options = {
    driver.raw_exec.enable = "1"
    docker.cleanup.image = false
  }
}

consul {
  address = "127.0.0.1:8500"
}

vault {
  enabled = true
  address = "VAULT_URL"
}
