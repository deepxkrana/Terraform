environment = "dev"
owner       = "platform-team"

services = {
  web = {
    port     = 80
    replicas = 3
  }

  worker = {
    port     = 9000
    replicas = 1
  }
}
