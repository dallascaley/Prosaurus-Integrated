terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.36.0"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-kind"
}

# Create a Kubernetes Deployment for a Docker container (nginx-based web server)
resource "kubernetes_deployment" "my_hello_world" {
  metadata {
    name = "my-hello-world-app"
    labels = {
      app = "hello-world"
    }
  }

  spec {
    replicas = 2  # Number of container replicas to run

    selector {
      match_labels = {
        app = "hello-world"
      }
    }

    template {
      metadata {
        labels = {
          app = "hello-world"
        }
      }

      spec {
        container {
          name  = "hello-world-container"
          image = "nginx:latest"  # This is a simple nginx server image

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# Optionally, create a service to expose your deployment
resource "kubernetes_service" "hello_world_service" {
  metadata {
    name = "hello-world-service"
  }

  spec {
    selector = {
      app = "hello-world"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "NodePort"  # Use NodePort for local clusters like Kind
  }
}

resource "kubernetes_namespace" "prosaurus-tf" {
  metadata {
    name = "prosaurus-k8s"
  }
}