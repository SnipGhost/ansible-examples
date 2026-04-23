variable "provider_username" {
    description = "Your VKCS provider account username"
    type        = string
    sensitive   = true
}

variable "provider_password" {
    description = "Your VKCS provider account password"
    type        = string
    sensitive   = true
}

variable "provider_project" {
    description = "Your VKCS provider project ID"
    type        = string
}

variable "provider_region" {
    description = "Your VKCS provider region name or ID"
    type = string
    default = "RegionOne"
}

variable "provider_auth_url" {
    description = "Your VKCS provider auth URL"
    type = string
}

variable "availability_zone_name" {
    description = "AZ name"
    type = string
    default = "GZ1"
}

variable "compute_flavor" {
    description = "Flavor name"
    type = string
    default = "STD2-1-1"
}
