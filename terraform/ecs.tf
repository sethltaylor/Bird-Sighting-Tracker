resource "aws_ecrpublic_repository" "bird_tracker_repo" {
    repository_name = "bird-tracker-repo"
}

resource "aws_ecs_cluster" "bird_tracker_cluster" {
    name = "bird-tracker-cluster"
}

resource "aws_ecs_task_definition" "bird_tracker_task" {
    family = "bird-tracker"
    network_mode = "awsvpc"
    runtime_platform {
      operating_system_family = "LINUX"
      cpu_architecture = "X86_64"
    }
    requires_compatibilities = [ "EC2" ]
    container_definitions = jsonencode([
        {
            name = "bird-tracker"
            image = "${aws_ecrpublic_repository.bird_tracker_repo.repository_uri}"
            cpu = 1
            memory = 3
            essential = true
            portMappings = [
                {
                containerPort = 8501
                hostPort = 8501
                protocol = "tcp"
                }
            ]
        }
    ])
    execution_role_arn = "${aws_iam_role.ecsTaskExecutionRole.arn}"
    task_role_arn = "${aws_iam_role.BirdTrackerTaskRole.arn}"
}

resource "aws_ecs_service" "bird_tracker_service" {
    name = "bird-tracker-service"
    cluster = aws_ecs_cluster.bird_tracker_cluster.id
    task_definition = aws_ecs_task_definition.bird_tracker_task.arn
    desired_count = 1

    network_configuration {
      subnets = [aws_subnet.public_subnet[0].id]
      security_groups = [ aws_security_group.bird_tracker_sg_tf.id ]
    }

    force_new_deployment = true 

    triggers = {
        redeployment = timestamp()
    }
}

resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
 name = "bird-tracker-capacity-provider"

 auto_scaling_group_provider {
   auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn

   managed_scaling {
     maximum_scaling_step_size = 1
     minimum_scaling_step_size = 1
     status                    = "ENABLED"
     target_capacity           = 1
   }
 }
}

resource "aws_ecs_cluster_capacity_providers" "bird_tracker_capacity_provider" {
 cluster_name = aws_ecs_cluster.bird_tracker_cluster.name

 capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]
}


resource "aws_alb" "ecs_alb" {
    name = "bird-tracker-load-balancer"
    load_balancer_type = "application"
    subnets = [aws_subnet.public_subnet[0].id, aws_subnet.public_subnet[1].id]
    security_groups = [ aws_security_group.bird_tracker_sg_tf.id ]
}

resource "aws_alb_target_group" "target_group" {
    name = "bird-tracker-target-group"
    port = 80
    protocol = "HTTP"
    target_type = "ip"
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