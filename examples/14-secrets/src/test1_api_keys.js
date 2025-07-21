// JavaScript file with API keys
const openaiApiKey = "sk-1234567890abcdef1234567890abcdef1234567890abcdef";
const stripeKey = "pk_live_51234567890abcdef1234567890abcdef";
const githubToken = "ghp_1234567890abcdef1234567890abcdef12345678";

// Configuration object
const config = {
    apiKey: "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
    secretKey: "AKIAIOSFODNN7EXAMPLE",
    refreshToken: "1//04567890abcdef1234567890abcdef1234567890"
};

// Safe environment variable reference (should not be flagged)
const envApiKey = process.env.API_KEY;

export { config, envApiKey };