provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-kind"
}

resource "kubernetes_namespace" "prosaurus-tf" {
  metadata {
    name = "prosaurus-k8s"
  }
}