# Function Calling Example

Local models are not all good at function calling, so this example uses a model that is specifically trained for function calling.

This is a list of models that are known to work well with function calling:

- `hf.co/salesforce/llama-xlam-2-8b-fc-r-gguf:q4_k_m`
- `hf.co/salesforce/xlam-2-3b-fc-r-gguf:q4_k_m`
- `hf.co/salesforce/xlam-2-3b-fc-r-gguf:q4_k_s`
- `hf.co/salesforce/xlam-2-3b-fc-r-gguf:q3_k_l`

## Run the example with compose

```bash
docker compose up --build -d --no-log-prefix 
docker attach $(docker compose ps -q tools-agent)

```

```bash
docker compose up --build -d --no-log-prefix 
docker attach $(docker compose ps -q tools-agent)
```
