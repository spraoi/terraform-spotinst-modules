variable "spotinst_token" {
  description = "The token used when accessing your Spotinst account"
}

variable "spotinst_account" {
  description = "Your Spotinst account"
}

variable "spotinst_cluster_identifier" {
  description = "This identifier should be identical to the clusterIdentifier that was configured on the Elastigroup."
}

variable enabled {
  description = "Change this to true to create a spotinst_ocean_controller resources"
  default     = "false"
}
