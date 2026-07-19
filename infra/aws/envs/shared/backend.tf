# Sau khi chạy bootstrap: thay REPLACE_ACCOUNT_ID bằng account id thật.
terraform {
  backend "s3" {
    bucket         = "sync-tfstate-REPLACE_ACCOUNT_ID"
    key            = "shared/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "sync-tf-lock"
    encrypt        = true
  }
}
