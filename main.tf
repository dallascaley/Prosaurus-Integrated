terraform {
  backend "remote" {
    organization = "Cherry-Blossom-Development"
    workspaces {
      name = "Development-Workspace"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-west-2"
}

resource "aws_instance" "app_server" {
  ami           = "ami-08d70e59c07c61a3a"
  instance_type = "t2.micro"

  # Add user_data for Kubernetes installation
  user_data = <<-EOF
              #!/bin/bash
              # Update the system
              sudo apt-get update -y && sudo apt-get upgrade -y

              # Install dependencies
              sudo apt-get install -y apt-transport-https curl

              # Add Kubernetes APT repository
              curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
              echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list

              # Install kubeadm, kubelet, and kubectl
              sudo apt-get update -y
              sudo apt-get install -y kubeadm kubelet kubectl

              # Mark them to hold the version
              sudo apt-mark hold kubeadm kubelet kubectl

              # Disable swap (required for kubeadm)
              sudo swapoff -a
              sudo sed -i '/swap/d' /etc/fstab

              # Initialize Kubernetes master node (this will require further configuration depending on your setup)
              sudo kubeadm init --pod-network-cidr=10.244.0.0/16

              # Set up kubeconfig for the root user
              mkdir -p $HOME/.kube
              sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
              sudo chown $(id -u):$(id -g) $HOME/.kube/config

              # Install Flannel CNI (Container Network Interface)
              kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

              # Enable kubelet to start on boot
              sudo systemctl enable kubelet
              sudo systemctl start kubelet
              EOF

  tags = {
    Name = var.instance_name
  }
}

variable "ssh_key_name" {
  description = "The name of the SSH key pair to use for EC2 access"
  type        = string
}