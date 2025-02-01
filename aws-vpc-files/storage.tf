resource "aws_ebs_volume" "mystorage" {
  availability_zone = "us-west-2a"
  size              = 10

  tags = {
    Name = "HelloWorld"
  }
}
