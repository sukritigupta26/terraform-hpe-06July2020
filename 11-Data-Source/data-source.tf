provider "google" {
  project     = "gleaming-design-282503"
  credentials = "${file("/tmp/account.json")}"
  region      = "us-west1"
}

provider "google" {
  project     = "gleaming-design-282503"
  credentials = "${file("/tmp/account.json")}"
  region      = "us-central1"
  alias       = "myregion"
}


data "google_compute_zones" "us-west1" {}

data "google_compute_zones" "us-central1" {
     provider = "google.myregion"
}

variable "multi-region-deployment" {
  default = false
}

variable "environment-name" {
  default = "tfdemo"
}



resource "google_compute_instance" "west_frontend" {
  depends_on 		= ["google_compute_instance.west_backend"]
  name     		= "${join("-",list(var.environment-name, "frontend-west"))}"
  count    		= "${var.multi-region-deployment ? 1 : 0}"
  zone     		= "${data.google_compute_zones.us-west1.names[count.index]}"
  machine_type 		= "f1-micro"
  boot_disk {
    initialize_params {
      image 		= "debian-cloud/debian-9"
    }
  }
  network_interface {
    # A default network is created for all GCP projects
    network       	= "default"
    access_config {
    }
  }
}

resource "google_compute_instance" "frontend" {
  provider      	= "google.myregion"
  name     		= "${join("-",list(var.environment-name, "frontend"))}"
  depends_on 		= ["google_compute_instance.backend"]
  count    		= 2
  #zone     		= "${var.us-central-zones[count.index]}"
  zone     		= "${data.google_compute_zones.us-central1.names[count.index]}"
  machine_type 		= "f1-micro"
  boot_disk {
    initialize_params {
      image 		= "debian-cloud/debian-9"
    }
  }
  network_interface {
    # A default network is created for all GCP projects
    network    		 = "default"
    access_config {
    }
  }
}


resource "google_compute_instance" "backend" {
  provider      		= "google.myregion"
  name     		        = "${join("-",list(var.environment-name, "backend"))}"
  machine_type 			= "f1-micro"
  count                 	= 1
  #zone     			= "${var.us-central-zones[count.index]}"
  zone     	        	= "${data.google_compute_zones.us-central1.names[count.index]}"
  boot_disk {
    initialize_params {
      image 			= "debian-cloud/debian-9"
    }
  }
  network_interface {
    # A default network is created for all GCP projects
    network       		= "default"
    access_config {
    }
  }
  lifecycle {
    prevent_destroy = false
  }
}


resource "google_compute_instance" "west_backend" {
  machine_type 			= "f1-micro"
  name     		        = "${join("-",list(var.environment-name, "backend-west"))}"
  count    		        = "${var.multi-region-deployment ? 2 : 0 }"
  #zone     			= "${var.us-west-zones[count.index]}"
  zone     		        = "${data.google_compute_zones.us-west1.names[count.index]}"
  boot_disk {
    initialize_params {
      image 			= "debian-cloud/debian-9"
    }
  }
  network_interface {
    # A default network is created for all GCP projects
    network       		= "default"
    access_config {
    }
  }
  lifecycle {
    prevent_destroy = false
  }
}


output "zones_west1" {
   value = "${data.google_compute_zones.us-west1.names}"
}

output "zones_central1" {
   value = "${data.google_compute_zones.us-central1.names}"
}
