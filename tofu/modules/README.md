# tofu/modules/

Reusable Terraform/OpenTofu modules shared across `tofu/stacks/`.

A module lands here once at least two stacks would reuse it. Until then,
keep resource declarations local to the consuming workspace.
