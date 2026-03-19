cluster_endpoint_public_access = true

maintenance_role_eks_access_entry_policy_associations = {
  eks_admin = {
    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
    access_scope = {
      type = "cluster"
    }
  }
  eks_view = {
    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    access_scope = {
      type = "cluster"
    }
  }
}

additional_namespaces = ["whoami"]

maintenance_cluster_role_rules_override = [{
  "apiGroups" = ["*"]
  "resources" = ["*"]
  "verbs"     = ["*"]
}]

min_size = 2
max_size = 3
desired_size = 2


{{ if gt (len .nuon.install_stack.outputs.custom_role_arns) 0 }}
additional_access_entry = {
  custom_1 = {
    principal_arn     = "{{ index .nuon.install_stack.outputs.custom_role_arns (printf "%s-custom-1" .nuon.install.id) }}"
    kubernetes_groups = []
    policy_associations = {
      cluster_admin = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        access_scope = {
          type       = "cluster"
          namespaces = []
        }
      }
      eks_admin = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
        access_scope = {
          type       = "cluster"
          namespaces = []
        }
      }
    }
  }
  custom_2 = {
    principal_arn     = "{{ index .nuon.install_stack.outputs.custom_role_arns (printf "%s-custom-2" .nuon.install.id) }}"
    kubernetes_groups = []
    policy_associations = {
      cluster_admin = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        access_scope = {
          type       = "cluster"
          namespaces = []
        }
      }
      eks_admin = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
        access_scope = {
          type       = "cluster"
          namespaces = []
        }
      }
    }
  }
  custom_3 = {
    principal_arn     = "{{ index .nuon.install_stack.outputs.custom_role_arns (printf "%s-custom-3" .nuon.install.id) }}"
    kubernetes_groups = []
    policy_associations = {
      cluster_admin = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        access_scope = {
          type       = "cluster"
          namespaces = []
        }
      }
      eks_admin = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
        access_scope = {
          type       = "cluster"
          namespaces = []
        }
      }
    }
  }
  whoami_deploy = {
    principal_arn     = "{{ index .nuon.install_stack.outputs.custom_role_arns (printf "%s-whoami-deploy" .nuon.install.id) }}"
    kubernetes_groups = []
    policy_associations = {
      edit = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
        access_scope = {
          type       = "namespace"
          namespaces = ["whoami"]
        }
      }
    }
  }
  whoami_teardown = {
    principal_arn     = "{{ index .nuon.install_stack.outputs.custom_role_arns (printf "%s-whoami-teardown" .nuon.install.id) }}"
    kubernetes_groups = []
    policy_associations = {
      edit = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
        access_scope = {
          type       = "namespace"
          namespaces = ["whoami"]
        }
      }
    }
  }
  alb_deploy = {
    principal_arn     = "{{ index .nuon.install_stack.outputs.custom_role_arns (printf "%s-alb-deploy" .nuon.install.id) }}"
    kubernetes_groups = []
    policy_associations = {
      edit = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
        access_scope = {
          type       = "namespace"
          namespaces = ["whoami"]
        }
      }
    }
  }
  alb_teardown = {
    principal_arn     = "{{ index .nuon.install_stack.outputs.custom_role_arns (printf "%s-alb-teardown" .nuon.install.id) }}"
    kubernetes_groups = []
    policy_associations = {
      edit = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
        access_scope = {
          type       = "namespace"
          namespaces = ["whoami"]
        }
      }
    }
  }
  deployments_status_trigger = {
    principal_arn     = "{{ index .nuon.install_stack.outputs.custom_role_arns (printf "%s-deployments-status-trigger" .nuon.install.id) }}"
    kubernetes_groups = []
    policy_associations = {
      view = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
        access_scope = {
          type       = "namespace"
          namespaces = ["whoami"]
        }
      }
    }
  }
  deployment_restart_trigger = {
    principal_arn     = "{{ index .nuon.install_stack.outputs.custom_role_arns (printf "%s-deployment-restart-trigger" .nuon.install.id) }}"
    kubernetes_groups = []
    policy_associations = {
      edit = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
        access_scope = {
          type       = "namespace"
          namespaces = ["whoami"]
        }
      }
    }
  }
  alb_trigger = {
    principal_arn     = "{{ index .nuon.install_stack.outputs.custom_role_arns (printf "%s-alb-trigger" .nuon.install.id) }}"
    kubernetes_groups = []
    policy_associations = {
      view = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
        access_scope = {
          type       = "namespace"
          namespaces = ["whoami"]
        }
      }
    }
  }
  alb_healthcheck_trigger = {
    principal_arn     = "{{ index .nuon.install_stack.outputs.custom_role_arns (printf "%s-alb-healthcheck-trigger" .nuon.install.id) }}"
    kubernetes_groups = []
    policy_associations = {
      view = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
        access_scope = {
          type       = "namespace"
          namespaces = ["whoami"]
        }
      }
    }
  }
  simple_demonstration_trigger = {
    principal_arn     = "{{ index .nuon.install_stack.outputs.custom_role_arns (printf "%s-simple-demonstration-trigger" .nuon.install.id) }}"
    kubernetes_groups = []
    policy_associations = {
      edit = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
        access_scope = {
          type       = "namespace"
          namespaces = ["whoami"]
        }
      }
    }
  }
}
{{ end }}
