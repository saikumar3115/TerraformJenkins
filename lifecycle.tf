/*

This example will be using the lifecycle metaargument which are use ful in some cases  

*/
  
resource "aws_instance" "ec2-user" {
  ami = ""
  type = "t2.micro"
  tags ={
    lifecycle {
      ignore_changes = all #all is the new keywords which will ignore all the attributes
    }
  }
}



resource "aws_instance" "ec2-user" {
  ami = ""
  type = "t2.micro"
  tags ={
    lifecycle {
      create_before_destroy = true # it would create the resource before the resource gets destroyed as by default behaviour of terraform is to destroy
    }
  }
}


resource "aws_instance" "ec2-user" {
  ami = ""
  type = "t2.micro"
  tags ={
    lifecycle {
      prevent_destroy = true # it would never allow terraform to destroy if this flag is set to true.
    }
  }
}
