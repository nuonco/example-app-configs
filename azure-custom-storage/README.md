# Azure Storage (custom stacks)

The Azure parallel of the GCS custom-stack pattern: a **compiled ARM custom stack**
creates a storage account during the customer's install-stack apply — as the
customer's admin credentials, before any component runs — and a pass-through
component reads it back and emits outputs for downstream use.

Azure custom stacks must be compiled ARM JSON. Sync rejects `.bicep` sources.

## How it works

1. Author the nested template in Bicep, then compile it before sync:

   ```bash
   az bicep build --file arm/storage.bicep --outfile arm/storage.json
   nuon apps sync
   ```

2. `stack.toml` points at the compiled JSON:

   ```toml
   [[custom_nested_stacks]]
   name         = "storage"
   template_url = "./arm/storage.json"
   index        = 0
   ```

   The install stack creates a globally unique storage account named
   `st` plus `uniqueString(resourceGroup().id, nuonInstallID)`. Parameters
   map to install inputs (here: `versioning` from `blob_versioning`).

3. Outputs phone home under
   `{{.nuon.install_stack.outputs.custom_nested_stacks.storage.outputs.*}}`.

4. `components/0-storage.toml` is a pass-through terraform component that reads
   the account by that output name and re-emits `name`, `id`, and
   `primary_blob_endpoint` — reference them from any other component as
   `{{.nuon.components.storage.outputs.name}}`.

## Requirements

The Azure subscription must have the storage resource provider registered:

```bash
az provider register --namespace Microsoft.Storage
```
