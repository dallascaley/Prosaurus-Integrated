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
  region = "us-west-2"
}

# Master Node
resource "aws_instance" "master" {
  ami           = "ami-08d70e59c07c61a3a"
  instance_type = "t2.micro"
  key_name      = var.ssh_key_name

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

              # Initialize Kubernetes master node
              sudo kubeadm init --pod-network-cidr=10.244.0.0/16

              # Set up kubeconfig for the root user
              mkdir -p $HOME/.kube
              sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
              sudo chown $(id -u):$(id -g) $HOME/.kube/config

              # Install Flannel CNI
              kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

              # Enable kubelet to start on boot
              sudo systemctl enable kubelet
              sudo systemctl start kubelet

              # Generate join token and save it to a file
              sudo kubeadm token create --print-join-command > /home/ubuntu/join_command.txt
              EOF

  tags = {
    Name = "k8s-master"
  }
}

# Worker Node
resource "aws_instance" "worker" {
  ami           = "ami-08d70e59c07c61a3a"
  instance_type = "t2.micro"
  key_name      = var.ssh_key_name

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
              EOF

  tags = {
    Name = "k8s-worker"
  }

  depends_on = [aws_instance.master]
}

# Upload and run join worker script
resource "null_resource" "join_worker" {
  depends_on = [aws_instance.worker, aws_instance.master]

  provisioner "remote-exec" {
    inline = [
      "echo 'Fetching join command from master node...'",
      "scp -i ${var.ssh_key_name} ec2-user@${aws_instance.master.public_ip}:/home/ubuntu/join_command.txt /tmp/join_command.txt",
      "chmod +x /tmp/join_worker.sh",
      "bash /tmp/join_worker.sh"
    ]

    connection {
      host        = aws_instance.worker.public_ip
      type        = "ssh"
      user        = "ec2-user"
      private_key = var.private_key_path
    }
  }

  provisioner "file" {
    source      = "scripts/join_worker.sh"
    destination = "/tmp/join_worker.sh"

    connection {
      host        = aws_instance.worker.public_ip
      type        = "ssh"
      user        = "ec2-user"
      private_key = var.private_key_path
    }
  }
}

# Output the Master Node IP
output "master_public_ip" {
  value = aws_instance.master.public_ip
}

# Output the Worker Node IP
output "worker_public_ip" {
  value = aws_instance.worker.public_ip
}

output "private_key_path" {
  value = var.private_key_path
}

variable "ssh_key_name" {
  description = "The name of the SSH key pair to use for EC2 access"
  type        = string
}

variable "private_key_path" {
  description = "The name of the SSH key path"
  type        = string
}
