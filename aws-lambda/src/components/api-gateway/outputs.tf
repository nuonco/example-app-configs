output "api_gateway" {
  value       = module.api_gateway
  description = "the api gateway"
}

output "api_gateway_arn" {
  value       = module.api_gateway.api_arn
  description = "the api gateway arn"
}
