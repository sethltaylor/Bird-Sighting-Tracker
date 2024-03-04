resource "aws_launch_configuration" "ecs_launch_config" {
  image_id                    = "ami-0fda8ddbf744d1fd4"
  iam_instance_profile        = aws_iam_instance_profile.ecs.arn
  security_groups             = [aws_security_group.bird_tracker_sg_tf.id]

  user_data                   = "#!/bin/bash\necho ECS_CLUSTER=bird-tracker-cluster >> /etc/ecs/ecs.config"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name = "ec2ecskey"
}

resource "aws_autoscaling_group" "ecs_asg" {
    name = "ECS EC2 ASG - Bird Tracker"
    vpc_zone_identifier = [aws_subnet.public_subnet[0].id, aws_subnet.public_subnet[1].id]
    launch_configuration = aws_launch_configuration.ecs_launch_config.name

    desired_capacity          = 1
    min_size                  = 1
    max_size                  = 1
    health_check_grace_period = 300
    health_check_type         = "EC2"
}