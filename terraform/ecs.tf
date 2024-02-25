resource "aws_ecrpublic_repository" "bird_tracker_repo" {
    repository_name = "bird-tracker-repo"
}

resource "aws_ecs_cluster" "bird_tracker_cluster" {
    name = "bird-tracker-cluster"
}

resource "aws_ecs_task_definition" "bird_tracker_task" {
    family = "bird-tracker"
    requires_compatibilities = [ "EC2" ]
    container_definitions = jsonencode([
        {
            name = "bird-tracker"
            image = "${aws_ecrpublic_repository.bird_tracker_repo.repository_uri}"
            cpu = 256
            memory = 512
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
    launch_type = "EC2"
    desired_count = 1

    load_balancer {
      target_group_arn = aws_alb_target_group.target_group.arn
      container_name = "bird-tracker"
      container_port = 8501
    }

    depends_on = [ aws_lb_listener.listener ]
}