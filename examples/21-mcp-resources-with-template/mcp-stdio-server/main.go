package main

import (
	"context"
	"errors"
	"log"
	"strings"

	"github.com/mark3labs/mcp-go/mcp"
	"github.com/mark3labs/mcp-go/server"
)

func extractID(template, uri string) string {
	// Replace the template placeholder with a split marker
	parts := strings.Split(strings.Replace(template, "{id}", "|||", 1), "|||")

	// Remove prefix and suffix from the URI
	result := strings.TrimPrefix(uri, parts[0])
	result = strings.TrimSuffix(result, parts[1])

	return result
}

func main() {

	// Create MCP server
	s := server.NewMCPServer(
		"rsrc-tpl-stdio-server",
		"0.0.0",
	)

	template := mcp.NewResourceTemplate(
		"users://{id}/profile", // URI with a template parameter {id}
		"User Profile",         // Description
		mcp.WithTemplateDescription("Returns the profile of a user by ID"),
		mcp.WithTemplateMIMEType("application/json"),
	)

	s.AddResourceTemplate(template, func(ctx context.Context, request mcp.ReadResourceRequest) ([]mcp.ResourceContents, error) {
		// Extract the user ID from the request
		userID := extractID("users://{id}/profile", request.Params.URI)

		if userID == "" {
			return nil, errors.New("user ID is required")
		}
		// Simulate fetching user profile data
		profileData := map[string]string{
			"id":   userID,
			"name": "User " + userID,
			"age":  "30",
		}
		// Return the profile data as JSON
		return []mcp.ResourceContents{
			mcp.TextResourceContents{
				URI:      request.Params.URI,
				MIMEType: "application/json",
				Text:     profileData["name"] + " is " + profileData["age"] + " years old.",
			},
		}, nil
	})

	// Start the stdio server
	if err := server.ServeStdio(s); err != nil {
		log.Fatalln("Failed to start server:", err)
		return
	}

}
