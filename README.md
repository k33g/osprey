# Osprey

**Osprey** is a lightweight Bash library for interacting with the DMR (**[Docker Model Runner](https://docs.docker.com/ai/model-runner/)**) API. It provides simple functions to perform chat completions, streaming responses, and conversation memory management with LLM models through **OpenAI-compatible APIs** (so, you can use it with other LLMs servers).

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
curl -fsSL https://github.com/k33g/osprey/releases/download/v0.0.8/osprey.sh -o ./osprey.sh
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

### Basic Chat Completion with Ollama

> Ollama provides an API compatible with OpenAI's chat completion endpoints. You can use Osprey to interact with Ollama models as follows:

```bash
BASE_URL=${OLLAMA_BASE_URL:-http://localhost:11434/v1}
MODEL=${OLLAMA_CHAT_MODEL:-"qwen2.5:latest"}

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
  echo -ne "$1" 
}

osprey_chat_stream ${DMR_BASE_URL} "${DATA}" callback
```

### Embeddings

Osprey provides functions for creating text embeddings and calculating similarity between vectors.

#### `osprey_create_embedding`

Creates text embeddings using the specified model through an OpenAI-compatible API:

```bash
DMR_BASE_URL="http://localhost:12434/engines/llama.cpp/v1"
MODEL="ai/nomic-embed-text:latest"

read -r -d '' DATA <<- EOM
{
  "model": "${MODEL}",
  "input": "The quick brown fox jumps over the lazy dog"
}
EOM

embedding=$(osprey_create_embedding ${DMR_BASE_URL} "${DATA}")
echo "${embedding}"
```

#### `cosine_similarity`

Calculates the cosine similarity between two embedding vectors. Returns a value between -1 and 1, where 1 indicates identical vectors, 0 indicates orthogonal vectors, and -1 indicates opposite vectors:

```bash
# Example vectors (in JSON array format)
vector1="[0.1, 0.2, 0.3, 0.4]"
vector2="[0.4, 0.3, 0.2, 0.1]"

similarity=$(cosine_similarity "$vector1" "$vector2")
echo "Similarity: $similarity"

# For word embeddings, similarities above 0.8 typically indicate semantically related content
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
> ✋ It seems there is a bug with Llama.cpp: [issue 14101](https://github.com/ggml-org/llama.cpp/issues/14101)

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

#### Loop function calling

For complex scenarios requiring multiple function calls and conversation flow management, Osprey provides functions to handle tool message loops:

##### `add_tool_calls_message`

Adds an assistant message with tool calls to the conversation history:

```bash
# Add assistant's tool calls to conversation
add_tool_calls_message CONVERSATION_HISTORY "$tool_calls"
```

##### `add_tool_message`

Adds a tool response message to the conversation history:

```bash
# Add function execution result to conversation
add_tool_message CONVERSATION_HISTORY "$tool_call_id" "$function_result"
```

##### `get_finish_reason`

Extracts the finish reason from the API response to determine if more tool calls are needed:

```bash
# Check if the model wants to make more function calls
finish_reason=$(get_finish_reason "$response")

if [[ "$finish_reason" == "tool_calls" ]]; then
    # Process tool calls and continue conversation
    echo "Model wants to make function calls"
else
    # Conversation is complete
    echo "Conversation finished: $finish_reason"
fi
```

These functions enable building conversational agents that can handle multi-step tool calling scenarios where the model may need to make several function calls and incorporate their results before providing a final response.

See the `examples/` directory for more detailed usage examples including conversation memory management.

## Using STDIO MCP Server

Osprey supports Model Context Protocol (MCP) servers with STDIO transport for extended function calling capabilities. You can use custom MCP servers that communicate via standard input/output to provide additional tools and functionalities.

### Setting up an MCP Server

First, build your MCP server Docker image:
```bash
cd examples/07-use-mcp/mcp-server
docker build -t osprey-mcp-server:demo .
```

### Using MCP Tools

```bash
#!/bin/bash
. "./osprey.sh"

DMR_BASE_URL="http://localhost:12434/engines/llama.cpp/v1"
MODEL="hf.co/salesforce/xlam-2-3b-fc-r-gguf:q4_k_s"

# Define the MCP server command
SERVER_CMD="docker run --rm -i osprey-mcp-server:demo"

# Get available tools from MCP server
MCP_TOOLS=$(get_mcp_tools "$SERVER_CMD")
TOOLS=$(transform_to_openai_format "$MCP_TOOLS")

read -r -d '' DATA <<- EOM
{
  "model": "${MODEL}",
  "options": {
    "temperature": 0.0
  },
  "messages": [
    {
      "role": "user",
      "content": "Say hello to Bob and calculate the sum of 5 and 37"
    }
  ],
  "tools": ${TOOLS},
  "parallel_tool_calls": true,
  "tool_choice": "auto"
}
EOM

# Make function call request
RESULT=$(osprey_tool_calls ${DMR_BASE_URL} "${DATA}")
TOOL_CALLS=$(get_tool_calls "${RESULT}")

# Process tool calls
for tool_call in $TOOL_CALLS; do
    FUNCTION_NAME=$(get_function_name "$tool_call")
    FUNCTION_ARGS=$(get_function_args "$tool_call")
    
    # Execute function via MCP
    MCP_RESPONSE=$(call_mcp_tool "$SERVER_CMD" "$FUNCTION_NAME" "$FUNCTION_ARGS")
    RESULT_CONTENT=$(get_tool_content "$MCP_RESPONSE")
    
    echo "Function result: $RESULT_CONTENT"
done
```

## Using Streamable HTTP MCP Server

Osprey supports MCP servers with streamable HTTP transport for real-time tool execution and response streaming. This allows for more interactive experiences with MCP tools that can provide streaming responses.

### Setting up a Streamable HTTP MCP Server

First, build your streamable HTTP MCP server Docker image:
```bash
cd examples/10-use-streamable-mcp/mcp-server
docker build -t osprey-streamable-mcp-server:demo .
```

Start the server:
```bash
docker run --rm -p 8080:8080 osprey-streamable-mcp-server:demo
```

### Using Streamable MCP Tools

```bash
#!/bin/bash
. "./osprey.sh"

DMR_BASE_URL="http://localhost:12434/engines/llama.cpp/v1"
MODEL="hf.co/salesforce/xlam-2-3b-fc-r-gguf:q4_k_s"

# Define the streamable HTTP MCP server endpoint
MCP_SERVER="http://localhost:9090"

# Get available tools from streamable MCP server
MCP_TOOLS=$(get_mcp_http_tools "$MCP_SERVER")
TOOLS=$(transform_to_openai_format "$MCP_TOOLS")

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

# Make function call request
RESULT=$(osprey_tool_calls ${DMR_BASE_URL} "${DATA}")
TOOL_CALLS=$(get_tool_calls "${RESULT}")

# Process tool calls with streaming support
for tool_call in $TOOL_CALLS; do
    FUNCTION_NAME=$(get_function_name "$tool_call")
    FUNCTION_ARGS=$(get_function_args "$tool_call")
        
    # Execute function via MCP
    MCP_RESPONSE=$(call_mcp_http_tool "$MCP_SERVER" "$FUNCTION_NAME" "$FUNCTION_ARGS")
    RESULT_CONTENT=$(get_tool_content_http "$MCP_RESPONSE")
    
    echo "Function result: $RESULT_CONTENT"
done
```

### Benefits of Streamable HTTP Transport

- **HTTP Standards**: Leverages standard HTTP streaming protocols
- **Scalability**: Easier to deploy and scale than STDIO servers

## Using Docker MCP Gateway

The Docker MCP Gateway provides access to a collection of pre-built MCP tools through Docker's MCP integration. This allows you to leverage existing MCP tools without setting up individual servers.

### Basic Usage

```bash
#!/bin/bash
. "./osprey.sh"

DMR_BASE_URL="http://localhost:12434/engines/llama.cpp/v1"
MODEL="hf.co/salesforce/xlam-2-3b-fc-r-gguf:q4_k_s"

# Use Docker MCP Gateway
SERVER_CMD="docker mcp gateway run"

# Get available tools and filter specific ones
MCP_TOOLS=$(get_mcp_tools "$SERVER_CMD")
TOOLS=$(transform_to_openai_format_with_filter "${MCP_TOOLS}" "search" "fetch")

read -r -d '' DATA <<- EOM
{
  "model": "${MODEL}",
  "options": {
    "temperature": 0.0
  },
  "messages": [
    {
      "role": "user",
      "content": "fetch https://raw.githubusercontent.com/k33g/osprey/refs/heads/main/README.md"
    }
  ],
  "tools": ${TOOLS},
  "tool_choice": "auto"
}
EOM

# Execute the request
RESULT=$(osprey_tool_calls ${DMR_BASE_URL} "${DATA}")
TOOL_CALLS=$(get_tool_calls "${RESULT}")

# Process tool calls
for tool_call in $TOOL_CALLS; do
    FUNCTION_NAME=$(get_function_name "$tool_call")
    FUNCTION_ARGS=$(get_function_args "$tool_call")
    
    # Execute function via MCP Gateway
    MCP_RESPONSE=$(call_mcp_tool "$SERVER_CMD" "$FUNCTION_NAME" "$FUNCTION_ARGS")
    RESULT_CONTENT=$(get_tool_content "$MCP_RESPONSE")
    
    echo "Function result: $RESULT_CONTENT"
done
```

### Tool Filtering

You can filter available tools using the `transform_to_openai_format_with_filter` function to only include tools that match specific criteria:

```bash
# Filter tools containing "search" or "fetch"
TOOLS=$(transform_to_openai_format_with_filter "${MCP_TOOLS}" "search" "fetch")
```

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

# Initialize conversation history array
CONVERSATION_HISTORY=()

function callback() {
  echo -ne "$1"
  # Accumulate assistant response to a temporary file
  echo -n "$1" >> /tmp/assistant_response.tmp
}

while true; do
  USER_CONTENT=$(gum write --placeholder "How can I help you?")
  
  if [[ "$USER_CONTENT" == "/bye" ]]; then
    break
  fi

  # Add user message to conversation history
  add_user_message CONVERSATION_HISTORY "${USER_CONTENT}"

  # Build messages array with conversation history
  MESSAGES=$(build_messages_array CONVERSATION_HISTORY)
  
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

  # Clear assistant response for this turn
  rm -f /tmp/assistant_response.tmp

  osprey_chat_stream ${DMR_BASE_URL} "${DATA}" callback

  # Read the accumulated response from the temp file
  ASSISTANT_RESPONSE=$(cat /tmp/assistant_response.tmp 2>/dev/null || echo "")

  # Add assistant response to conversation history
  add_assistant_message CONVERSATION_HISTORY "${ASSISTANT_RESPONSE}"
  
  echo -e "\n"
done
```

This creates a fully interactive, containerized AI agent with conversation memory and streaming responses.
