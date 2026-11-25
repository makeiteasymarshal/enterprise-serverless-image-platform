module "network" {
  source = "../../modules/network"

  name               = "${var.project_name}-${var.environment}"
  availability_zones = var.availability_zones

  tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = "personal-lab"
  }
}
