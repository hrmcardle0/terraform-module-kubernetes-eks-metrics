// Cluster Name
variable "cluster_name" {
  type        = string
  description = "A naming prefix added to all provisioned resources."

  validation {
    condition     = can(regex("^[a-zA-Z]{0,99}$", var.prefix))
    error_message = "The cluster need must be between 1 and 100 characters long."
  }
}