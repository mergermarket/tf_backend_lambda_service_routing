variable "env" {
  description = "The name of the environment (included at the front of the DNS name with a hyphen if not live)"
}

variable "component_name" {
  type        = "string"
  description = "The name of the component - used by default for the DNS entry (with the -service suffix removed), as well as to give the target group a meaningful name"
  default     = ""
}

variable "override_dns_name" {
  type        = "string"
  description = "The first part of the DNS name without the environment (defaults to component_name with -service suffix removed)"
  default     = ""
}

variable "dns_domain" {
  description = "The top level domain the service should live under - e.g. mmgapi.net"
}

variable "ttl" {
  description = "Time to live"
  default     = "60"
}

variable "alb_dns_name" {
  description = "The DNS name of the ALB to point the DNS at"
}

variable "alb_listener_arn" {
  description = "The ARN of the ALB listener to add the rule to."
}

variable "priority" {
  description = "ALB listener rule priority"
}

