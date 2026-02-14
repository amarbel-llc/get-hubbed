package tools

import "github.com/amarbel-llc/go-lib-mcp/server"

func RegisterAll() *server.ToolRegistry {
	r := server.NewToolRegistry()

	registerRepoTools(r)
	registerIssueTools(r)
	registerPRTools(r)

	return r
}
