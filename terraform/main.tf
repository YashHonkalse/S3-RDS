# S3 Bucket
resource "aws_s3_bucket" "S3-RDS" {
  bucket = "221bbks"
}

# RDS Database (MySQL)
resource "aws_db_instance" "rds_instance" {
  identifier          = "rds-instance"
  engine              = "mysql"
  engine_version      = "8.0.35"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  db_name             = "mydatabase"
  username            = "yash"
  password            = "EdMuNd1234"
  publicly_accessible = false
  skip_final_snapshot = true
}



# AWS ECR Repository 
resource "aws_ecr_repository" "S3-RDS-repo" {
  name = "s3-rds-repo"
}

# Glue Database
resource "aws_glue_catalog_database" "glue_db" {
  name = "error_glue_db"
}

# Glue Table
resource "aws_glue_catalog_table" "glue_table" {
  name          = "failed_data"
  database_name = aws_glue_catalog_database.glue_db.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "json"
  }

  storage_descriptor {
    columns {
      name = "failed_record"
      type = "string"
    }

    location      = "s3://221bbks/glue-failed-data/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hive.hcatalog.data.JsonSerDe"
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda-policy"
  description = "IAM policy for Lambda function to access S3, RDS, and logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::221bbks",
          "arn:aws:s3:::221bbks/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds-data:ExecuteStatement"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "s3_to_rds_lambda" {
  function_name = "s3-to-rds-lambda"
  role          = aws_iam_role.lambda_role.arn

  package_type = "Image"
  image_uri    = "971422685558.dkr.ecr.ap-southeast-2.amazonaws.com/s3-rds-repo:latest"

  timeout     = 60
  memory_size = 512
}

resource "aws_s3_bucket_notification" "s3_lambda_trigger" {
  bucket = aws_s3_bucket.S3-RDS.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_to_rds_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_to_rds_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.S3-RDS.arn
}