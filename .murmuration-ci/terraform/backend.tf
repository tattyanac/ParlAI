terraform {
  backend "s3" {
    bucket = "parlai-s3-statefile"
    region = "us-west-1"
    key    = "current.tfstate"
  }
}