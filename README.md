# Terraform Structure

Terraform Structure is built for testing needs.

## Usage

Insert variables into variables.tf file, initiate terraform and wait until Windows EC2 instances install all required software.

```terraform
terraform init
terraform plan
terraform apply
```

##Important Note
You should wait until script change index.html to our test static page from S3 Bucket.

## Delete

To delete all resources and create EC2 instances again with custom webpages do:

```terraform
terraform destroy
terraform apply
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.
