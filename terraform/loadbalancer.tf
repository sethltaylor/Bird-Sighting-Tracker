resource "aws_alb" "ecs_alb" {
    name = "bird-tracker-load-balancer"
    load_balancer_type = "application"
    subnets = [aws_subnet.public_subnet[0].id, aws_subnet.public_subnet[1].id]
    security_groups = [ aws_security_group.bird_tracker_sg_tf.id ]
}

resource "aws_alb_target_group" "target_group" {
    name = "bird-tracker-target-group"
    port = 8501
    protocol = "HTTP"
    target_type = "instance"
    vpc_id = aws_vpc.main.id
}

resource "aws_lb_listener" "listener" {
    load_balancer_arn = aws_alb.ecs_alb.arn
    port = "80"
    protocol = "HTTP"
    default_action {
      type = "forward"
      target_group_arn = aws_alb_target_group.target_group.arn
    }
}