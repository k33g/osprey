# Compose Agent Example

This example demonstrates how to create a containerized AI chatbot using Docker Compose and the Osprey library. The example creates "Seven of Nine", a Star Trek-themed AI assistant that speaks like a Borg character.

## What it does

- Creates a containerized AI agent using Docker Compose
- Downloads and configures the Osprey library for AI interactions
- Implements a conversational chat interface using `gum` for user input
- Maintains conversation history throughout the chat session
- Uses streaming responses for real-time interaction
- Configures the AI with a Star Trek character persona (Seven of Nine from Borg)

## Features

- **Containerized deployment**: Runs entirely in Docker with all dependencies included
- **Interactive chat**: Uses `gum write` for a pleasant command-line chat experience
- **Conversation memory**: Maintains full conversation history for context
- **Streaming responses**: Real-time token-by-token response generation
- **Character roleplay**: Pre-configured with Seven of Nine personality and Borg speech patterns
- **Easy exit**: Type `/bye` to end the conversation

## Usage

### Option 1: Run with Docker Compose (Recommended)

```bash
docker compose up --build -d --no-log-prefix 
docker attach $(docker compose ps -q seven-of-nine-agent)
```

### Option 2: Run locally
> - First, ensure you have the Osprey library installed as described in the [README](../README.md).
> - Then, pull the model with: `docker model pull ai/qwen2.5:latest`
```bash
MODEL_RUNNER_BASE_URL=http://localhost:12434/engines/llama.cpp/v1 \
MODEL_RUNNER_CHAT_MODEL=ai/qwen2.5:latest \
SYSTEM_INSTRUCTION="You are an expert of the StarTrek universe." \
./main.sh
```

## Configuration

The agent is configured through environment variables:
- `MODEL_RUNNER_BASE_URL`: The base URL of your model server
- `MODEL_RUNNER_CHAT_MODEL`: The specific model to use (default: ai/qwen2.5:latest)
- `SYSTEM_INSTRUCTION`: The character prompt defining the AI's personality and behavior
