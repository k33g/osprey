package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/mark3labs/mcp-go/mcp"
	"github.com/mark3labs/mcp-go/server"
)

func main() {

	// Create MCP server
	s := server.NewMCPServer(
		"mcp-http-demo",
		"0.0.0",
	)

	// =================================================
	// TOOLS:
	// =================================================
	sayHello := mcp.NewTool("say_hello",
		mcp.WithDescription("Say hello to the user"),
		mcp.WithString("name",
			mcp.Required(),
			mcp.Description("The name of the person to greet"),
		),
	)

	s.AddTool(sayHello, sayHelloHandler)

	calculateSum := mcp.NewTool("calculate_sum",
		mcp.WithDescription("Calculate the sum of two numbers"),
		mcp.WithNumber("a",
			mcp.Required(),
			mcp.Description("The first number"),
		),
		mcp.WithNumber("b",
			mcp.Required(),
			mcp.Description("The second number"),
		),
	)

	s.AddTool(calculateSum, calculateSumHandler)

	// Start the HTTP server
	httpPort := os.Getenv("HTTP_PORT")
	if httpPort == "" {
		httpPort = "9090"
	}

	log.Println("MCP StreamableHTTP server is running on port", httpPort)

	server.NewStreamableHTTPServer(s,
		server.WithEndpointPath("/mcp"),
	).Start(":" + httpPort)
}

func sayHelloHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	args := request.GetArguments()
	if name, exists := args["name"]; exists {
		return mcp.NewToolResultText(fmt.Sprintf("👋 Hello %s 🙂", name)), nil
	} else {
		return mcp.NewToolResultText("😡 error - no name"), nil
	}
}

func calculateSumHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	args := request.GetArguments()
	if a, exists := args["a"]; exists {
		if b, exists := args["b"]; exists {
			sum := a.(float64) + b.(float64)
			return mcp.NewToolResultText(fmt.Sprintf("The sum of %v and %v is %v", a, b, sum)), nil
		}
		return mcp.NewToolResultText("😡 error - no second number"), nil
	}
	return mcp.NewToolResultText("😡 error - no first number"), nil
}
