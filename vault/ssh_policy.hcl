# This section grants write access on ssh-nomad/creds/otp_nomad
path "ssh-nomad/creds/otp_nomad" {
  capabilities = ["create", "update" ]
}

# This section gives read access on the rest of the ssh-nomad path
path "ssh-nomad/*" {
  capabilities = ["read"]
}
