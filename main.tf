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

# Create a Kubernetes Deployment for a Docker container
resource "kubernetes_deployment" "breakroom" {
  metadata {
    name = "breakroom-app"
    namespace = kubernetes_namespace.prosaurus-tf.metadata[0].name
    labels = {
      app = "breakroom"
    }
  }

  spec {
    replicas = 2  # Number of container replicas to run

    selector {
      match_labels = {
        app = "breakroom"
      }
    }

    template {
      metadata {
        labels = {
          app = "breakroom"
        }
      }

      spec {
        container {
          name  = "breakroom-container"
          image = "dallascaley/breakroom:latest"
          image_pull_policy = "Always"  # Ensures Kubernetes pulls the image every time

          port {
            container_port = 80
          }
        }
      }
    }
  }

  timeouts {
    create = "2m"  # Timeout for creation after 2 minutes
    update = "2m"  # Timeout for updates after 2 minutes
  }
}

# Optionally, create a service to expose your deployment
resource "kubernetes_service" "breakroom_service" {
  metadata {
    name = "breakroom-service"
    namespace = kubernetes_namespace.prosaurus-tf.metadata[0].name
  }

  spec {
    selector = {
      app = "breakroom"
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