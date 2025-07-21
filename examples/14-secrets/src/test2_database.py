# Python file with database credentials
import os

# Database connection strings with credentials
DATABASE_URL = "postgresql://admin:supersecret123@db.example.com:5432/production"
MONGO_URI = "mongodb://dbuser:mypassword456@cluster0.mongodb.net/myapp"
MYSQL_CONNECTION = "mysql://root:admin123@localhost:3306/webapp"

# Individual credential variables
DB_PASSWORD = "mySecretPassword789"
DB_USER = "administrator"
DB_HOST = "production-db.company.com"

# Redis connection with auth
REDIS_URL = "redis://:secretredispass@redis.example.com:6379/0"

# Safe environment variable usage (should not be flagged)
safe_db_url = os.getenv("DATABASE_URL")
safe_password = os.environ.get("DB_PASSWORD")

class DatabaseConfig:
    def __init__(self):
        self.password = "hardcoded_secret_123"  # This should be flagged
        self.host = "localhost"  # This is safe