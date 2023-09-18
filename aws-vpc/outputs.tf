output "vpc_id" {
  value = aws_vpc.main
}

output "private_subnet_ids" {
  value = aws_subnet.private
}

output "public_subnet_ids" {
  value = aws_subnet.public
}

output "nat_subnet_id" {
  value = aws_nat_gateway.gateway
}

output "public_route_table_ids" {
  value = [aws_route_table.public.id]
}

output "vpc_main_route_table_id" {
  value = aws_vpc.main.main_route_table_id
}