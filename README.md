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

DATA='{
  "model":"'${MODEL}'",
  "messages": [
    {"role":"user", "content": "Hello, how are you?"}
  ],
  "stream": false
}'

response=$(osprey_chat ${DMR_BASE_URL} "${DATA}")
echo "${response}"
```

### Streaming Chat
```bash
DMR_BASE_URL="http://localhost:12434/engines/llama.cpp/v1"
MODEL="ai/qwen2.5:latest"

DATA='{
  "model":"'${MODEL}'",
  "messages": [
    {"role":"user", "content": "Hello, how are you?"}
  ],
  "stream": true
}'

function callback() {
  echo -n "$1" 
}

osprey_chat_stream ${DMR_BASE_URL} "${DATA}" callback
```

See the `examples/` directory for more detailed usage examples including conversation memory management.
