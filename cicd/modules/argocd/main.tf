################################################################################
# ArgoCD Namespace
################################################################################

resource "kubernetes_namespace" "argocd-namespace" {
  metadata {
    annotations = {
      name = "argocd"
    }

    labels = {
      app = "argocd"
    }

    name = "argocd"
  }
}

################################################################################
# ArgoCD Policy
################################################################################

module "argocd_iam_policy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = "argocd-policy"
  path        = "/"
  description = "ArgoCD Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ec2:*"]
        Resource = "*"
      }
    ]
  })

}

################################################################################
# ArgoCD Role
################################################################################

module "argocd_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${var.env_name}_eks_argocd"

  role_policy_arns = {
    policy = module.argocd_iam_policy.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["argocd:argocd-sa"]
    }
  }
}

################################################################################
# ArgoCD Service Account
################################################################################

resource "kubernetes_service_account" "service-account" {
  metadata {
    name      = "argocd-sa"
    namespace = "argocd"
    labels = {
      "app.kubernetes.io/name" = "argocd-sa"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = module.argocd_role.iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

################################################################################
# Install ArgoCD With Helm
################################################################################

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  depends_on = [
    kubernetes_service_account.service-account
  ]

  values = [
    "${file("${path.module}/templates/values.yaml")}"
  ]

  set {
    name  = "region"
    value = var.main-region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "argocd-sa"
  }

  set {
    name  = "clusterName"
    value = var.cluster_name
  }
}


