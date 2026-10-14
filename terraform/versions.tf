terraform {
  required_version = ">= 1.0"

  required_providers {
    vbox = {
      source  = "eran132/vbox"
      version = "2.1.1"
    }
  }
}

provider "vbox" {}
