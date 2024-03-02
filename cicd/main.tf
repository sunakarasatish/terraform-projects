################################################################################
# ArgoCD
################################################################################

module "argocd" {
  source = "./modules/argocd"

  main-region  = var.main-region
  env_name     = var.env_name
  cluster_name = var.cluster_name

  vpc_id            = var.vpc_id
  oidc_provider_arn = var.oidc_provider_arn
}
