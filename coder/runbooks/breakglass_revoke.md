Closes break-glass cluster access. This deletes the EKS access entry for the break-glass role (`{{ .nuon.install.id }}-coder-sandbox-break-glass`), which also removes its associated `AmazonEKSClusterAdminPolicy`. After this runs, the role keeps its AWS `AdministratorAccess` but can no longer operate inside the EKS cluster.

Push **Run runbook** when you are finished with a break-glass session. It is safe to run at any time — if no access entry exists, it is a no-op and reports `not_found`.

Run the `breakglass_grant` runbook to open access again.
