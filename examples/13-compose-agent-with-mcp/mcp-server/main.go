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

	s.AddTool(calculateSum, func(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		args := request.GetArguments()
		if a, exists := args["a"]; exists {
			if b, exists := args["b"]; exists {
				sum := a.(float64) + b.(float64)
				return mcp.NewToolResultText(fmt.Sprintf("The sum of %v and %v is %v", a, b, sum)), nil
			}
			return mcp.NewToolResultText("😡 error - no second number"), nil
		}
		return mcp.NewToolResultText("😡 error - no first number"), nil
	})

	calculateSubtract := mcp.NewTool("calculate_subtract",
		mcp.WithDescription("Calculate the difference between two numbers"),
		mcp.WithNumber("a",
			mcp.Required(),
			mcp.Description("The first number"),
		),
		mcp.WithNumber("b",
			mcp.Required(),
			mcp.Description("The second number"),
		),
	)

	s.AddTool(calculateSubtract, func(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		args := request.GetArguments()
		if a, exists := args["a"]; exists {
			if b, exists := args["b"]; exists {
				difference := a.(float64) - b.(float64)
				return mcp.NewToolResultText(fmt.Sprintf("The difference between %v and %v is %v", a, b, difference)), nil
			}
			return mcp.NewToolResultText("😡 error - no second number"), nil
		}
		return mcp.NewToolResultText("😡 error - no first number"), nil
	})

	calculateMultiply := mcp.NewTool("calculate_multiply",
		mcp.WithDescription("Calculate the product of two numbers"),
		mcp.WithNumber("a",
			mcp.Required(),
			mcp.Description("The first number"),
		),
		mcp.WithNumber("b",
			mcp.Required(),
			mcp.Description("The second number"),
		),
	)

	s.AddTool(calculateMultiply, func(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		args := request.GetArguments()
		if a, exists := args["a"]; exists {
			if b, exists := args["b"]; exists {
				product := a.(float64) * b.(float64)
				return mcp.NewToolResultText(fmt.Sprintf("The product of %v and %v is %v", a, b, product)), nil
			}
			return mcp.NewToolResultText("😡 error - no second number"), nil
		}
		return mcp.NewToolResultText("😡 error - no first number"), nil
	})

	calculateDivide := mcp.NewTool("calculate_divide",
		mcp.WithDescription("Calculate the division of two numbers"),
		mcp.WithNumber("a",
			mcp.Required(),
			mcp.Description("The numerator"),
		),
		mcp.WithNumber("b",
			mcp.Required(),
			mcp.Description("The denominator"),
		),
	)

	s.AddTool(calculateDivide, func(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		args := request.GetArguments()
		if a, exists := args["a"]; exists {
			if b, exists := args["b"]; exists {
				if b.(float64) == 0 {
					return mcp.NewToolResultText("😡 error - division by zero"), nil
				}
				quotient := a.(float64) / b.(float64)
				return mcp.NewToolResultText(fmt.Sprintf("The quotient of %v and %v is %v", a, b, quotient)), nil
			}
			return mcp.NewToolResultText("😡 error - no second number"), nil
		}
		return mcp.NewToolResultText("😡 error - no first number"), nil
	})

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

