/*
  This will set an example of for_each loop with set of strings
  here we key and value are same i.e each.key=each.value
*/
      
    resource "aws_iam_user" "terraform-iamuser"{
      
      for_each= toset{[ "tom" , "dick" , "harry" ]}
      
      name = "${each.key}"
      
      tags ={
        
        "Name"  = "${each.value}" 
      }
      
    }
