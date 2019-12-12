resource "kubernetes_config_map" "configmap" {
  count = var.enabled == "true" ? 1 : 0

  metadata {
    name      = "spotinst-kubernetes-cluster-controller-config"
    namespace = "kube-system"
  }

  data = {
    "spotinst.token"              = var.spotinst_token
    "spotinst.account"            = var.spotinst_account
    "spotinst.cluster-identifier" = var.spotinst_cluster_identifier
  }
}

resource "kubernetes_secret" "default" {
  count = var.enabled == "true" ? 1 : 0

  metadata {
    name      = "spotinst-kubernetes-cluster-controller-certs"
    namespace = "kube-system"

    labels = {
      k8s-app = "spotinst-kubernetes-cluster-controller"
    }
  }

  type = "Opaque"
}

resource "kubernetes_service_account" "default" {
  count = var.enabled == "true" ? 1 : 0

  metadata {
    name      = "spotinst-kubernetes-cluster-controller"
    namespace = "kube-system"

    labels = {
      k8s-app = "spotinst-kubernetes-cluster-controller"
    }
  }

  automount_service_account_token = true
}

resource "kubernetes_cluster_role" "default" {
  count = var.enabled == "true" ? 1 : 0

  metadata {
    name = "spotinst-kubernetes-cluster-controller"
  }

  # ---------------------------------------------------------------------------
  # Required for functional operation (read-only).
  # ---------------------------------------------------------------------------

  rule {
    api_groups = [""]
    resources  = ["pods", "nodes", "services", "namespaces", "replicationcontrollers", "limitranges", "events", "persistentvolumes", "persistentvolumeclaims"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "statefulsets"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["replicasets", "daemonsets"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["pods"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers"]
    verbs      = ["get", "list"]
  }

  rule {
    non_resource_urls = ["/version/", "/version"]
    verbs             = ["get"]
  }

  # ---------------------------------------------------------------------------
  # Required by the draining feature and for functional operation.
  # ---------------------------------------------------------------------------

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["patch", "update"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/eviction"]
    verbs      = ["create"]
  }

  # ---------------------------------------------------------------------------
  # Required by the Spotinst Auto Update feature.
  # ---------------------------------------------------------------------------

  rule {
    api_groups     = ["rbac.authorization.k8s.io"]
    resources      = ["clusterroles"]
    resource_names = ["spotinst-kubernetes-cluster-controller"]
    verbs          = ["patch", "update", "escalate"]
  }

  rule {
    api_groups     = ["apps"]
    resources      = ["deployments"]
    resource_names = ["spotinst-kubernetes-cluster-controller"]
    verbs          = ["patch", "update"]
  }

  # ---------------------------------------------------------------------------
  # Required by the Spotinst Apply feature.
  # ---------------------------------------------------------------------------

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets"]
    verbs      = ["get", "list", "patch", "update", "create", "delete"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["daemonsets"]
    verbs      = ["get", "list", "patch", "update", "create", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "patch", "update", "create", "delete"]
  }
}

resource "kubernetes_cluster_role_binding" "default" {
  count = var.enabled == "true" ? 1 : 0

  metadata {
    name = "spotinst-kubernetes-cluster-controller"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "spotinst-kubernetes-cluster-controller"
  }

  subject {
    api_group = ""
    kind      = "ServiceAccount"
    name      = "spotinst-kubernetes-cluster-controller"
    namespace = "kube-system"
  }
}

resource "kubernetes_deployment" "default" {
  count = var.enabled == "true" ? 1 : 0

  metadata {
    name      = "spotinst-kubernetes-cluster-controller"
    namespace = "kube-system"

    labels = {
      k8s-app = "spotinst-kubernetes-cluster-controller"
    }
  }

  spec {
    replicas               = 1
    revision_history_limit = 10

    selector {
      match_labels = {
        k8s-app = "spotinst-kubernetes-cluster-controller"
      }
    }

    template {
      metadata {
        labels = {
          k8s-app = "spotinst-kubernetes-cluster-controller"
        }
      }

      spec {
        container {
          image             = "spotinst/kubernetes-cluster-controller:${data.external.version.result["version"]}"
          name              = "spotinst-kubernetes-cluster-controller"
          image_pull_policy = "Always"

          volume_mount {
            name       = "spotinst-kubernetes-cluster-controller-certs"
            mount_path = "/certs"
          }

          volume_mount {
            mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
            name       = kubernetes_service_account.default[0].default_secret_name
            read_only  = true
          }

          liveness_probe {
            http_get {
              path = "/healthcheck"
              port = 4401
            }

            initial_delay_seconds = 300
            period_seconds        = 20
            timeout_seconds       = 2
            success_threshold     = 1
            failure_threshold     = 3
          }

          env {
            name = "SPOTINST_TOKEN"

            value_from {
              config_map_key_ref {
                name = "spotinst-kubernetes-cluster-controller-config"
                key  = "spotinst.token"
              }
            }
          }

          env {
            name = "SPOTINST_ACCOUNT"

            value_from {
              config_map_key_ref {
                name = "spotinst-kubernetes-cluster-controller-config"
                key  = "spotinst.account"
              }
            }
          }

          env {
            name = "CLUSTER_IDENTIFIER"

            value_from {
              config_map_key_ref {
                name = "spotinst-kubernetes-cluster-controller-config"
                key  = "spotinst.cluster-identifier"
              }
            }
          }

          env {
            name = "POD_ID"

            value_from {
              field_ref {
                field_path = "metadata.uid"
              }
            }
          }

          env {
            name = "POD_NAME"

            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }

          env {
            name = "POD_NAMESPACE"

            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }
        }

        volume {
          name = "spotinst-kubernetes-cluster-controller-certs"

          secret {
            secret_name = "spotinst-kubernetes-cluster-controller-certs"
          }
        }

        volume {
          name = kubernetes_service_account.default[0].default_secret_name

          secret {
            secret_name = kubernetes_service_account.default[0].default_secret_name
          }
        }

        service_account_name = "spotinst-kubernetes-cluster-controller"

        toleration {
          key                = "node.kubernetes.io/not-ready"
          effect             = "NoExecute"
          operator           = "Exists"
          toleration_seconds = 150
        }

        toleration {
          key                = "node.kubernetes.io/unreachable"
          effect             = "NoExecute"
          operator           = "Exists"
          toleration_seconds = 150
        }

        toleration {
          key      = "node-role.kubernetes.io/master"
          operator = "Exists"
        }
      }
    }
  }
}

data "external" "version" {
  program = ["curl", "https://spotinst-public.s3.amazonaws.com/integrations/kubernetes/cluster-controller/latest.json"]
}

