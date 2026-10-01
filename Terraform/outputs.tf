# Get public IP
output "Master_node_public_ip" {
  description = "Public ip"
  value       = aws_instance.Master_node.public_ip
}

# Get private IP
output "Master_node_private_ip" {
  description = "Private IP"
  value       = aws_instance.Master_node.private_ip
}

# Get public IP
output "Worker_node_1_public_ip" {
  description = "Public ip"
  value       = aws_instance.Worker_node_1.public_ip
}

# Get private IP
output "Worker_node_1_private_ip" {
  description = "Private IP"
  value       = aws_instance.Worker_node_1.private_ip
}

# Get public IP
output "Worker_node_2_public_ip" {
  description = "Public ip"
  value       = aws_instance.Worker_node_2.public_ip
}

# Get private IP
output "Worker_node_2_private_ip" {
  description = "Private IP"
  value       = aws_instance.Worker_node_2.private_ip
}

# Get name Master_node
output "Master_node_name {
  description = "Name"
  value       = aws_instance.Master_node.tags.name
}

# Get name Worker_node_1
output "Worker_node_name_1" {
  description = "Private IP"
  value       = aws_instance.Worker_node_1.tags.name
}

# Get name Worker_node_2
output "Worker_node_name_2" {
  description = "Private IP"
  value       = aws_instance.Worker_node_2.tags.name
}