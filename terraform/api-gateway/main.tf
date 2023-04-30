resource "aws_api_gateway_rest_api" "this" {
  name        = var.hello_world_lambda.lambda_name
  description = "Terraform Serverless Application - ${var.hello_world_lambda.lambda_name}"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : {
        "Effect" = "Allow"

        "Principal" = "*"
        "Action" = [
          "execute-api:Invoke"
        ]
        "Resource" : [
          "execute-api:/*"
        ]
      }
    }
  )
}

resource "aws_api_gateway_resource" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = var.resource_path
}

resource "aws_api_gateway_method" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.this.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_method.this.resource_id
  http_method = aws_api_gateway_method.this.http_method

  integration_http_method = "GET"
  type                    = "AWS"
  uri                     = data.aws_lambda_function.this.invoke_arn
}


resource "aws_api_gateway_method_response" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.this.id
  http_method = aws_api_gateway_method.this.http_method
  status_code = "200"
}
resource "aws_api_gateway_integration_response" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.this.id
  http_method = aws_api_gateway_method.this.http_method
  status_code = aws_api_gateway_method_response.this.status_code
}
resource "aws_api_gateway_deployment" "this" {
  depends_on = [
    "aws_api_gateway_integration.this",
  ]

  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = var.environment
}

resource "aws_lambda_permission" "this" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}
