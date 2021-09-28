variable "region_var" {
    type = string
}

variable "intancetype_var" {
  type = string
}
variable "accesskey_var" {
  type = string
}

variable "secretkey_var" {
  type =  string
}
variable "filename" {
  type = string
}
variable "amis"{
   type = map(string)
   default = {
     "ap-south-1" = "ami-0c1a7f89451184c8b"
   }
}