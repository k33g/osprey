// TypeScript file with mostly safe code (should have minimal or no secrets)
export interface Config {
  apiUrl: string;
  timeout: number;
  retries: number;
}

// Safe environment variable usage
const apiKey = process.env.API_KEY;
const dbUrl = process.env.DATABASE_URL;

// Safe placeholder values
const exampleConfig: Config = {
  apiUrl: "https://api.example.com",
  timeout: 5000,
  retries: 3
};

// Test data (should not be flagged as secrets)
const testData = {
  username: "testuser",
  password: "testpass",  // This might be flagged but is just test data
  token: "test-token-123"  // This might be flagged but is just test data
};

// Comments indicating test/example data
const mockApiKey = "sk-example-key-for-testing-only";  // Example key for documentation

// Safe utility functions
export function validateApiKey(key: string): boolean {
  return key.startsWith('sk-') && key.length > 20;
}

export function buildDatabaseUrl(host: string, database: string): string {
  const user = process.env.DB_USER;
  const pass = process.env.DB_PASS;
  return `postgresql://${user}:${pass}@${host}/${database}`;
}