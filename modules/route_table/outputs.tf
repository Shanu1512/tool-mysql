output "private_rt_id" {
  value = length(aws_route_table.private) > 0 ? aws_route_table.private[0].id : ""
}

# output "public_rt_id" {
#   value = aws_route_table.public[0].id
# }

output "public_rt_id" {
  value       = length(aws_route_table.public) > 0 ? aws_route_table.public[0].id : ""
  description = "Public Route Table ID"
}
 