locals {
  ssh_key_pair_name = "ssh-${var.region}"
  firewall_rules = {
    22  = ["0.0.0.0/0"]
    80  = ["0.0.0.0/0"]
    443 = ["0.0.0.0/0"]
  }
}
