# Place Index (reverse/search) + Route Calculator (challenge polylines).
# Names match AwsLocation__* env on order/social ECS tasks.

resource "aws_location_place_index" "main" {
  count = var.create_aws_location_resources ? 1 : 0

  index_name  = var.aws_location_place_index_name
  data_source = var.aws_location_place_data_source

  data_source_configuration {
    intended_use = "SingleUse"
  }

  tags = {
    Name = "${var.env}-${var.aws_location_place_index_name}"
    Env  = var.env
  }
}

resource "aws_location_route_calculator" "main" {
  count = var.create_aws_location_resources ? 1 : 0

  calculator_name = var.aws_location_route_calculator_name
  data_source     = var.aws_location_route_data_source

  tags = {
    Name = "${var.env}-${var.aws_location_route_calculator_name}"
    Env  = var.env
  }
}
