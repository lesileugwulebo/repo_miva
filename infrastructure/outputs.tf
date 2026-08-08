output "aws_vpc_id" {
  value = aws_vpc.main.id
}

output "aws_transit_gateway_id" {
  value = aws_ec2_transit_gateway.main.id
}

output "aws_vpn_connection_1_id" {
  value = aws_vpn_connection.gcp_1.id
}

output "aws_vpn_connection_2_id" {
  value = aws_vpn_connection.gcp_2.id
}

output "aws_service_private_ip" {
  value = aws_instance.service.private_ip
}

output "gcp_application_private_ip" {
  value = google_compute_instance.application.network_interface[0].network_ip
}

output "gcp_database_private_ip" {
  value     = google_compute_instance.database.network_interface[0].network_ip
  sensitive = true
}

output "gcp_load_balancer_ip" {
  value = google_compute_global_forwarding_rule.web_forwarding_rule.ip_address
}

output "vpn_connection_summary" {
  value = {
    aws_connection_1 = aws_vpn_connection.gcp_1.id
    aws_connection_2 = aws_vpn_connection.gcp_2.id
    gcp_tunnel_1_1   = google_compute_vpn_tunnel.t1_1.name
    gcp_tunnel_1_2   = google_compute_vpn_tunnel.t1_2.name
    gcp_tunnel_2_1   = google_compute_vpn_tunnel.t2_1.name
    gcp_tunnel_2_2   = google_compute_vpn_tunnel.t2_2.name
  }
}
