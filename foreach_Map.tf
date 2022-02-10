/*
  This config file gives details about the for each with respect to map(dictionary)
    here we can access both key and value which is each.key and each.value
*/
      
    resource "aws_s3_bucket" "terraform-s3bucket" {
    
        for_each = {
          dev = "dev-env"
          test = "test-env"
          staging = "staging-env"
          prod = "prod-env"
        }
      
    }
