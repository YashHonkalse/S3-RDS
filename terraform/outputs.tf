output "s3_bucket_name" {
  value = aws_s3_bucket.S3-RDS.bucket
}

output "rds_endpoint" {
  value = aws_db_instance.rds_instance.endpoint
}

output "ecr_repository_url" {
  value = aws_ecr_repository.S3-RDS-repo.repository_url
}
