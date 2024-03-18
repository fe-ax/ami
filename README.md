# AMI's by Packer

This Packer config creates the selected Packer images in `buildlist`.

## Using the Packer config

```bash
cd packer

# To test your build without creating the AMI
packer build -var-file=packer.pkrvar.hcl aws-k3s.pkr.hcl

# To create the AMI
packer build -var 'skip_create_ami=false' -var-file=packer.pkrvar.hcl aws-k3s.pkr.hcl
```