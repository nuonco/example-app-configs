terraform {
  backend "http" {
    lock_method    = "POST"
    unlock_method  = "POST"
    address        = "http://localhost:8081/v1/terraform-backend?workspace_id=tfwtyx7usobkmcguu3417h8tu0&org_id=org22xwt28yn4lwzi9e1jm7ssu"
    lock_address   = "http://localhost:8081/v1/terraform-workspaces/tfwtyx7usobkmcguu3417h8tu0/lock?org_id=org22xwt28yn4lwzi9e1jm7ssu"
    unlock_address = "http://localhost:8081/v1/terraform-workspaces/tfwtyx7usobkmcguu3417h8tu0/unlock?org_id=org22xwt28yn4lwzi9e1jm7ssu"
  }
}
