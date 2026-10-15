output "address" {
  value       = google_sql_database_instance.sonar.private_ip_address
  description = "Private IP address of the Cloud SQL instance."
}

output "connection_name" {
  value = google_sql_database_instance.sonar.connection_name
}

output "db_instance_name" {
  value = google_sql_database_instance.sonar.name
}

output "db_instance_port" {
  value = "5432"
}

output "db_instance_username" {
  value = google_sql_user.sonar.name
}

output "db_password" {
  value     = random_password.sonar_db_password.result
  sensitive = true
}

output "database_name" {
  value = google_sql_database.sonar.name
}
