
/*
https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-metrics.html

Variables: 
1. var.environment - contains the environment name such as prod or dev

Create all the resources needed for EKS monitoring
1. namespace - holds all cloudwatch k8s resources
2. service account - used for access control
3. cluster role & cluster role binding - used for access control
4. config map - contains configuration items for metric metrics collection
5. daemonset - runs one metric-collecting pod on each node
*/

resource "kubernetes_namespace" "amazon_cloudwatch_namespace" {
  metadata {
    annotations = {
      name = "amazon-cloudwatch"
    }

    labels = {
      name = "amazon-cloudwatch"
    }

    name = "amazon-cloudwatch"
  }
}

resource "kubernetes_service_account" "amazon_cloudwatch_service_account" {
  metadata {
    name      = "cloudwatch-agent"
    namespace = kubernetes_namespace.amazon_cloudwatch_namespace.metadata.0.annotations.name
  }
}

resource "kubernetes_cluster_role" "amazon_cloudwatch_cluster_role" {
  metadata {
    name = "cloudwatch-agent-role"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "nodes", "endpoints"]
    verbs      = ["list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["replicasets"]
    verbs      = ["list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs"]
    verbs      = ["list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes/proxy"]
    verbs      = ["get"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes/stats", "configmaps", "events"]
    verbs      = ["create"]
  }

  rule {
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["cwagent-clusterleader"]
    verbs          = ["get", "update"]
  }
}

resource "kubernetes_cluster_role_binding" "amazon_cloudwatch_cluster_role_binding" {
  metadata {
    name = "cloudwatch-agent-role-binding"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "cloudwatch-agent"
    namespace = "amazon-cloudwatch"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "cloudwatch-agent-role"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_config_map" "amazon-cloudwatch-config-map" {
  metadata {
    name      = "cwagentconfig"
    namespace = "amazon-cloudwatch"
  }

  data = {
    "cwagentconfig.json" = jsonencode({
      "logs" : {
        "metrics_collected" : {
          "kubernetes" : {
            "cluster_name" : "${var.cluster_name}",
            "metrics_collection_interval" : 60
          }
        },
        "force_flush_interval" : 5
      }
    })
  }
}

resource "kubernetes_daemonset" "amazon-cloudwatch-daemonset" {
  metadata {
    name      = "cloudwatch-agent"
    namespace = "amazon-cloudwatch"
  }

  spec {
    selector {
      match_labels = {
        name = "cloudwatch-agent"
      }
    }

    template {
      metadata {
        labels = {
          name = "cloudwatch-agent"
        }
      }

      spec {
        container {
          image = "amazon/cloudwatch-agent:1.247348.0b251302"
          name  = "cloudwatch-agent"

          resources {
            limits = {
              cpu    = "200m"
              memory = "200Mi"
            }
            requests = {
              cpu    = "200m"
              memory = "200Mi"
            }
          }

          env {
            name = "HOST_IP"
            value_from {
              field_ref {
                field_path = "status.hostIP"
              }
            }
          }

          env {
            name = "HOST_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }

          env {
            name = "K8S_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }

          env {
            name  = "CI_VERSION"
            value = "k8s/1.3.8"
          }

          volume_mount {
            name       = "cwagentconfig"
            mount_path = "/etc/cwagentconfig"
          }
          volume_mount {
            name       = "rootfs"
            mount_path = "/rootfs"
            read_only  = "true"
          }
          volume_mount {
            name       = "dockersock"
            mount_path = "/var/run/docker.sock"
            read_only  = "true"
          }
          volume_mount {
            name       = "varlibdocker"
            mount_path = "/var/lib/docker"
            read_only  = "true"
          }
          volume_mount {
            name       = "containerdsock"
            mount_path = "/run/containerd/containerd.sock"
            read_only  = "true"
          }
          volume_mount {
            name       = "sys"
            mount_path = "/sys"
            read_only  = "true"
          }
          volume_mount {
            name       = "devdisk"
            mount_path = "/dev/disk"
            read_only  = "true"
          }
        }
        volume {
          name = "cwagentconfig"
          config_map {
            name = "cwagentconfig"
          }
        }
        volume {
          name = "rootfs"
          host_path {
            path = "/"
          }
        }
        volume {
          name = "dockersock"
          host_path {
            path = "/var/run/docker.sock"
          }
        }
        volume {
          name = "varlibdocker"
          host_path {
            path = "/var/lib/docker"
          }
        }
        volume {
          name = "containerdsock"
          host_path {
            path = "/run/containerd/containerd.sock"
          }
        }
        volume {
          name = "sys"
          host_path {
            path = "/sys"
          }
        }
        volume {
          name = "devdisk"
          host_path {
            path = "/dev/disk"
          }
        }
        termination_grace_period_seconds = "60"
        service_account_name             = "cloudwatch-agent"
      }
    }

  }
}