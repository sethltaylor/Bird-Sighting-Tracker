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
    deregistration_delay = 5
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

resource "aws_lb_listener" "https_listener" {
    load_balancer_arn = aws_alb.ecs_alb.arn
    port              = 443
    protocol          = "HTTPS"
    ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"  
    certificate_arn   = "arn:aws:acm:us-east-1:851725613770:certificate/9750229d-1433-4930-bf4c-7c71b6ba7cd7"

    default_action {
        type             = "forward"
        target_group_arn = aws_alb_target_group.target_group.arn
    }
}