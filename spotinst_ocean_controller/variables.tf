variable "spotinst_token" {
  description = "Your Spotinst Personal Access token"
}

variable "spotinst_account" {
  description = "Your Spotinst account ID"
}

variable "spotinst_cluster_identifier" {
  description = "Your cluster identifier"
}

variable enabled {
  description = "Change this to true to create a spotinst_ocean_controller resources"
  default     = "false"
}
