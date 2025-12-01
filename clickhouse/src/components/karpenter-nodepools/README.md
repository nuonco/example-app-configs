# Nodepools

This helm module manages the creation of the karpenter nodepools and their
corresponding EC2 Node Classes. Nodepools and EC2NodeClasses have a 1:1
correspondence. Each nodepool gets a nodeclass w/ the same name.

To be fair, we're overloading the definition by using a single nodepool list to
generate both but it's fine for now.

## Notes

We are not doing anything fancy w/ these node classes at this point in time, so
the EC2NodeClasses are created so we do not have to separate these two later if
we decide to do something differently.
