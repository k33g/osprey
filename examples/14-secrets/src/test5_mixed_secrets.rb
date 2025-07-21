# Ruby file with various types of secrets
require 'base64'

class AppConfig
  # Slack webhook URL with token
  SLACK_WEBHOOK = "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
  
  # Discord bot token
  DISCORD_TOKEN = "ODcyNzM0NTU4Mjc0MDQyODkw.YQ4H7w.SomeSecretTokenHere123456789"
  
  # Base64 encoded API key (should be decoded and flagged)
  ENCODED_SECRET = "c2stMTIzNDU2Nzg5MGFiY2RlZjEyMzQ1Njc4OTBhYmNkZWY="  # sk-1234567890abcdef1234567890abcdef
  
  # FTP URL with credentials
  FTP_URL = "ftp://username:password123@ftp.example.com/uploads"
  
  # SMTP configuration
  SMTP_PASSWORD = "emailpassword456"
  SMTP_USER = "noreply@company.com"
  
  # Session secret
  SESSION_SECRET = "super-secret-session-key-that-should-be-random"
  
  # Safe configuration (should not be flagged)
  APP_NAME = "MyApplication"
  PORT = 3000
  ENVIRONMENT = "production"
end

# Method that uses environment variables (safe)
def get_api_key
  ENV['API_KEY'] || 'default-key'
end

# Hardcoded password in method (should be flagged)
def authenticate_admin
  admin_password = "admin123456"
  # authentication logic here
end