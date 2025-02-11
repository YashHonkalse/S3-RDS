import boto3
import pymysql
import pandas as pd
import logging

# Logging Setup
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger()

# AWS Config
S3_BUCKET = "221bbks"
S3_FILE_KEY = "yash_credentials.csv"

# RDS Config (Hardcoded)
RDS_HOST = "rds-instance.cbis4o8km9ly.ap-southeast-2.rds.amazonaws.com"
RDS_PORT = 3306
RDS_USER = "yash"
RDS_PASSWORD = "EdMuNd1234"
RDS_DB = "mydatabase"

# Initialize AWS Clients
s3_client = boto3.client("s3")

def main(event, context):
    """
    AWS Lambda function to process data from S3 to RDS.
    """
    try:
        local_file = "/tmp/data.csv"
        
        # Download from S3
        logger.info("Downloading file from S3...")
        s3_client.download_file(S3_BUCKET, S3_FILE_KEY, local_file)
        
        # Read CSV in chunks to handle large files
        chunk_size = 500  # Process 500 rows at a time
        df_iter = pd.read_csv(local_file, chunksize=chunk_size)

        # Connect to RDS
        logger.info("Connecting to RDS...")
        conn = pymysql.connect(
            host=RDS_HOST,
            user=RDS_USER,
            password=RDS_PASSWORD,
            database=RDS_DB,
            port=RDS_PORT,
            cursorclass=pymysql.cursors.DictCursor,
        )
        cursor = conn.cursor()

        # Process CSV in chunks
        for df in df_iter:
            if not {"column1", "column2"}.issubset(df.columns):
                raise ValueError("CSV file is missing required columns: column1, column2")
            
            for _, row in df.iterrows():
                try:
                    cursor.execute(
                        "INSERT INTO my_table (column1, column2) VALUES (%s, %s)",
                        (row["column1"], row["column2"])
                    )
                except Exception as row_err:
                    logger.error(f"Error inserting row: {row} -> {row_err}")

        conn.commit()
        cursor.close()
        conn.close()
        
        return {"statusCode": 200, "body": "✅ Data successfully inserted into RDS"}

    except Exception as e:
        logger.error(f"❌ Error: {e}")
        return {"statusCode": 500, "body": str(e)}

