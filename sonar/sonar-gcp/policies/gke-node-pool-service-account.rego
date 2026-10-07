# GKE Node Pool Service Account Policy
#
# This policy ensures that GKE node pools use a dedicated service account
# instead of the default Compute Engine service account, which has the
# overly permissive Editor role.
#
# Use Case:
# - Enforce principle of least privilege on GKE nodes
# - Prevent use of the default Compute Engine SA (Editor role)
# - Comply with GKE hardening guidelines
#
# Policy Type: terraform_module
# Engine: opa
#
# Example violation:
# ```hcl
# resource "google_container_node_pool" "bad" {
#   node_config {
#     # No service_account specified — defaults to Compute Engine SA
#     oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
#   }
# }
# ```

package nuon

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# Deny node pools without an explicit service account
deny contains msg if {
    some resource_change in input.plan.resource_changes
    resource_change.type == "google_container_node_pool"
    resource_change.change.actions[_] in ["create", "update"]

    resource := resource_change.change.after

    # service_account is missing or empty
    not resource.node_config[0].service_account

    msg := sprintf(
        "GKE node pool '%s' does not specify a service account. This defaults to the Compute Engine SA which has Editor role. Create a dedicated least-privilege service account.",
        [resource_change.address]
    )
}

# Deny node pools without an explicit service account
warn contains msg if {
    some resource_change in input.plan.resource_changes
    resource_change.type == "google_container_node_pool"
    resource_change.change.actions[_] in ["create", "update"]

    resource := resource_change.change.after
    sa := resource.node_config[0].service_account

    # Match the default Compute Engine SA pattern
    endswith(sa, "-compute@developer.gserviceaccount.com")

    msg := sprintf(
        "GKE node pool '%s' uses the default Compute Engine service account ('%s'). This SA has the Editor role and is overly permissive. Use a dedicated least-privilege service account.",
        [resource_change.address, sa]
    )
}
