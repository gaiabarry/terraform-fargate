data "aws_availability_zones" "available" {}

data "aws_iam_role" "ecsTaskRole" {
  name = "ecsTaskExecutionRole"
}


# VPC
resource "aws_vpc" "vpc_res" {
  cidr_block = "172.32.0.0/16"
  tags = {
    Name = "demo-vpc"
  }
}

resource "aws_subnet" "subnet_res" {
  count             = length(data.aws_availability_zones.available.names)
  cidr_block        = cidrsubnet(aws_vpc.vpc_res.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.vpc_res.id
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc_res.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.vpc_res.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

# ECS cluster
resource "aws_ecs_cluster" "cluster" {
  name = "demo-ecs-cluster"
}

resource "aws_ecs_task_definition" "task_definition_res" {
  family                   = "fargate-task"
  execution_role_arn       = data.aws_iam_role.ecsTaskRole.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  container_definitions = jsonencode(
    [
      {
        name        = "demo-task-definition"
        image       = var.app_image
        networkMode = "awsvpc"
        "logConfiguration" : {
          "logDriver" : "awslogs",
          "options" : {
            "awslogs-group" : var.log_group,
            "awslogs-region" : var.aws_region,
            "awslogs-stream-prefix" : "ecs"
          }
        }
      }
    ]
  )
}

resource "aws_ecs_service" "service_res" {
  name            = "demo-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task_definition_res.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    security_groups  = [aws_security_group.service_sg.id]
    subnets          = aws_subnet.subnet_res.*.id
    assign_public_ip = true
  }
}

resource "aws_security_group" "service_sg" {
  name   = "demo-security-group"
  vpc_id = aws_vpc.vpc_res.id
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}