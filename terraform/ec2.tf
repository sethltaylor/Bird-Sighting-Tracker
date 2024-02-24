resource "aws_launch_template" "ecs_lt" {
 name_prefix   = "ecs-template"
 image_id      = "ami-0440d3b780d96b29d"
 instance_type = "t2.micro"

 key_name               = "ec2ecskey"
 vpc_security_group_ids = [aws_security_group.bird_tracker_sg_tf.id]
 iam_instance_profile {
   name = "ecsInstanceRole"
 }

 block_device_mappings {
   device_name = "/dev/xvda"
   ebs {
     volume_size = 30
     volume_type = "gp3"
   }
 }

 tag_specifications {
   resource_type = "instance"
   tags = {
     Name = "ecs-instance"
   }
 }

   user_data = base64encode(<<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.bird_tracker_cluster.name} >> /etc/ecs/ecs.config
              EOF
  )
}

resource "aws_autoscaling_group" "ecs_asg" {
    vpc_zone_identifier = [aws_subnet.public_subnet[0].id, aws_subnet.public_subnet[1].id]
    desired_capacity = 1
    max_size = 1
    min_size = 1

    launch_template {
      id = aws_launch_template.ecs_lt.id
      version = "$Latest"
    }

    tag {
        key = "AmazonECSManaged"
        value = true
        propagate_at_launch = true
    }
}