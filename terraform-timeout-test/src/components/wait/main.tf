resource "time_sleep" "wait" {
  create_duration = "15m"
}

output "completed_at" {
  value = time_sleep.wait.id
}
