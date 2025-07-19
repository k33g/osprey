# Osprey

**Osprey** is a lightweight Bash library for interacting with the DMR (**[Docker Model Runner](https://docs.docker.com/ai/model-runner/)**) API. It provides simple functions to perform chat completions, streaming responses, and conversation memory management with LLM models through OpenAI-compatible APIs.

## Features

- **Chat Completions**: Send messages to LLM models and receive responses
- **Streaming Support**: Real-time streaming responses for interactive applications
- **Conversation Memory**: Built-in functions to manage chat history and context
- **Simple Integration**: Easy-to-use Bash functions that work with any OpenAI-compatible API

## Requirements
- `jq` - A lightweight and flexible command-line JSON processor.
- `curl` - A command-line tool for transferring data with URLs.
- `bash` - A Unix shell and command language.
- [`gum`](https://github.com/charmbracelet/gum) - A tool for creating interactive command-line applications.


## Install the library
```bash
curl -fsSL https://github.com/k33g/osprey/releases/download/v0.0.0/osprey.sh -o ./osprey.sh
chmod +x ./osprey.sh
```

## Usage

Source the library in your script:
```bash
. "./osprey.sh"
```

### Basic Chat Completion
```bash
DMR_BASE_URL="http://localhost:12434/engines/llama.cpp/v1"
MODEL="ai/qwen2.5:latest"

read -r -d '' DATA <<- EOM
{
  "model":"'${MODEL}'",
  "messages": [
    {"role":"user", "content": "Hello, how are you?"}
  ],
  "stream": false
}
EOM

response=$(osprey_chat ${DMR_BASE_URL} "${DATA}")
echo "${response}"
```

### Streaming Chat
```bash
DMR_BASE_URL="http://localhost:12434/engines/llama.cpp/v1"
MODEL="ai/qwen2.5:latest"

read -r -d '' DATA <<- EOM
{
  "model":"'${MODEL}'",
  "messages": [
    {"role":"user", "content": "Hello, how are you?"}
  ],
  "stream": true
}
EOM

function callback() {
  echo -n "$1" 
}

osprey_chat_stream ${DMR_BASE_URL} "${DATA}" callback
```

### Function Calling
```bash
DMR_BASE_URL="http://localhost:12434/engines/llama.cpp/v1"
MODEL="hf.co/salesforce/xlam-2-3b-fc-r-gguf:q4_k_s"

# Define your tools in JSON format
read -r -d '' TOOLS <<- EOM
[
  {
    "type": "function",
    "function": {
      "name": "calculate_sum",
      "description": "Calculate the sum of two numbers",
      "parameters": {
        "type": "object",
        "properties": {
          "a": {"type": "number", "description": "The first number"},
          "b": {"type": "number", "description": "The second number"}
        },
        "required": ["a", "b"]
      }
    }
  }
]
EOM

read -r -d '' DATA <<- EOM
{
  "model":"'${MODEL}'",
  "messages": [
    {"role":"user", "content": "Calculate the sum of 5 and 10"}
  ],
  "tools": '${TOOLS}',
  "tool_choice": "auto"
}
EOM

# Make the function call request
response=$(osprey_tool_calls ${DMR_BASE_URL} "${DATA}")

# Extract and process tool calls
TOOL_CALLS=$(get_tool_calls "${response}")
for tool_call in $TOOL_CALLS; do
    FUNCTION_NAME=$(get_function_name "$tool_call")
    FUNCTION_ARGS=$(get_function_args "$tool_call")
    CALL_ID=$(get_call_id "$tool_call")
    
    # Execute your function logic here
    case "$FUNCTION_NAME" in
        "calculate_sum")
            A=$(echo "$FUNCTION_ARGS" | jq -r '.a')
            B=$(echo "$FUNCTION_ARGS" | jq -r '.b')
            SUM=$((A + B))
            echo "Result: $SUM"
            ;;
    esac
done
```

**Note on Parallel Tool Calls**: The `parallel_tool_calls` parameter enables models to make multiple function calls simultaneously. However, only a few local models support this feature effectively:
- `hf.co/salesforce/llama-xlam-2-8b-fc-r-gguf:q4_k_m`
- `hf.co/salesforce/xlam-2-3b-fc-r-gguf:q4_k_m`
- `hf.co/salesforce/xlam-2-3b-fc-r-gguf:q4_k_s`
- `hf.co/salesforce/xlam-2-3b-fc-r-gguf:q3_k_l`

Example with parallel tool calls:
```bash
read -r -d '' DATA <<- EOM
{
  "model": "${MODEL}",
  "options": {
    "temperature": 0.0
  },
  "messages": [
    {
      "role": "user",
      "content": "Say hello to Bob and to Sam, make the sum of 5 and 37"
    }
  ],
  "tools": ${TOOLS},
  "parallel_tool_calls": true,
  "tool_choice": "auto"
}
EOM
```

See the `examples/` directory for more detailed usage examples including conversation memory management.

## Creating an Agent with Agentic Compose

You can create containerized AI agents using Docker Compose for easy deployment and management. The `examples/05-compose-agent/` directory demonstrates how to build a complete agentic system.

### Quick Start

```bash
cd examples/05-compose-agent/
docker compose up --build -d
docker attach $(docker compose ps -q seven-of-nine-agent)
```

### Agent Architecture

The agentic compose setup includes:

- **Containerized Environment**: Complete isolation with all dependencies
- **Interactive Interface**: Uses `gum` for enhanced command-line interactions
- **Conversation Memory**: Persistent chat history throughout sessions
- **Streaming Responses**: Real-time token generation
- **Character Personas**: Configurable system instructions for roleplay

### Configuration

Configure your agent through `compose.yml`:

```yaml
services:
  your-agent:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        - OSPREY_VERSION=v0.0.1
    tty: true
    stdin_open: true
    environment:
      SYSTEM_INSTRUCTION: |
        You are a helpful AI assistant.
        Your role is to...
    models:
      chat_model:
        endpoint_var: MODEL_RUNNER_BASE_URL
        model_var: MODEL_RUNNER_CHAT_MODEL

models:
  chat_model:
    model: ai/qwen2.5:latest
```

### Agent Script Structure

```bash
#!/bin/bash
. "./osprey.sh"

# Initialize conversation
CONVERSATION_HISTORY=()

function callback() {
  echo -n "$1"
  ASSISTANT_RESPONSE+="$1"
}

while true; do
  USER_CONTENT=$(gum write --placeholder "How can I help you?")
  
  if [[ "$USER_CONTENT" == "/bye" ]]; then
    break
  fi

  add_user_message "$USER_CONTENT"
  build_messages_array
  
  # Create API request with conversation history
  read -r -d '' DATA <<- EOM
{
  "model":"${MODEL}",
  "options": {
    "temperature": 0.5,
    "repeat_last_n": 2
  },
  "messages": [${MESSAGES}],
  "stream": true
}
EOM
  
  ASSISTANT_RESPONSE=""
  osprey_chat_stream ${DMR_BASE_URL} "${DATA}" callback
  add_assistant_message "$ASSISTANT_RESPONSE"
  
  echo -e "\n"
done
```

This creates a fully interactive, containerized AI agent with conversation memory and streaming responses.
