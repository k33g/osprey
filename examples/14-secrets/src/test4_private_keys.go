package main

import "fmt"

// SSH private key embedded in code
const sshPrivateKey = `-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA4f5wg5l2hKsTeNem/V41fGnJm6gCD+n4bYmNw5EXAMPLE
MIIEowIBAAKCAQEA4f5wg5l2hKsTeNem/V41fGnJm6gCD+n4bYmNw5EXAMPLE
MIIEowIBAAKCAQEA4f5wg5l2hKsTeNem/V41fGnJm6gCD+n4bYmNw5EXAMPLE
-----END RSA PRIVATE KEY-----`

// Certificate content
var tlsCert = `-----BEGIN CERTIFICATE-----
MIIDXTCCAkWgAwIBAgIJAKoK/heBjcOuMA0GCSqGSIb3DQEBBQUAMEUxCzAJBgNV
BAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEwHwYDVQQKDBhJbnRlcm5ldCBX
-----END CERTIFICATE-----`

// JWT signing secret
var jwtSecret = "myJWTSigningSecret123456789"

// API configuration
type Config struct {
    PrivateKey string
    Password   string
    Host       string
}

func main() {
    config := Config{
        PrivateKey: "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwgg...\n-----END PRIVATE KEY-----",
        Password:   "myHardcodedPassword123",
        Host:       "api.example.com", // This is safe
    }
    
    fmt.Printf("Config loaded: %+v\n", config)
}