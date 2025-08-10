package main

import (
	"context"
	"log"
	"os"

	"github.com/mark3labs/mcp-go/mcp"
	"github.com/mark3labs/mcp-go/server"
)

func main() {

	// Create MCP server
	s := server.NewMCPServer(
		"rsrc-stdio-server",
		"0.0.0",
	)

	// Static golangResource example
	golangResource := mcp.NewResource(
		"snippets://golang",
		"some golang snippets",
		mcp.WithResourceDescription("A collection of golang code snippets"),
		mcp.WithMIMEType("text/markdown"),
	)

	// Add resource with its handler
	s.AddResource(golangResource, func(ctx context.Context, request mcp.ReadResourceRequest) ([]mcp.ResourceContents, error) {

		content, err := os.ReadFile("snippets-golang.md")
		if err != nil {
			return nil, err
		}

		return []mcp.ResourceContents{
			mcp.TextResourceContents{
				URI:      "snippets://golang",
				MIMEType: "text/markdown",
				Text:     string(content),
			},
		}, nil
	})

	rustResource := mcp.NewResource(
		"snippets://rust",
		"some rust snippets",
		mcp.WithResourceDescription("A collection of rust code snippets"),
		mcp.WithMIMEType("text/markdown"),
	)
	// Add resource with its handler
	s.AddResource(rustResource, func(ctx context.Context, request mcp.ReadResourceRequest) ([]mcp.ResourceContents, error) {

		content, err := os.ReadFile("snippets-rustlang.md")
		if err != nil {
			return nil, err
		}

		return []mcp.ResourceContents{
			mcp.TextResourceContents{
				URI:      "snippets://rust",
				MIMEType: "text/markdown",
				Text:     string(content),
			},
		}, nil
	})


	// Start the stdio server
	if err := server.ServeStdio(s); err != nil {
		log.Fatalln("Failed to start server:", err)
		return
	}

}
