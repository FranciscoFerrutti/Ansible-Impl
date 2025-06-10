resource "aws_apigatewayv2_integration" "lambda_integration" {
    api_id = var.api_id
    integration_type = "AWS_PROXY"
    integration_uri = var.lambda_arn
    integration_method = "POST"
    payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "lambda_route" {
    api_id = var.api_id
    route_key = "${var.method} /${var.name}"
    target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.api_id}/*/*"
}
