region            = "us-east-1"
ami               = "ami-36f43e4b"
server_instance_type = "t2.medium"
client_instance_type = "t2.medium"
key_name          = ""
server_count      = "1"
client_count      = "2"
name_tag_prefix   = "nomad-consul"
owner_tag_value = ""
token_for_nomad = "5a6dd64c-4c3f-6141-3751-ae68f82e45cd"
vault_url = "http://ec2-54-215-103-114.us-west-1.compute.amazonaws.com:8200"