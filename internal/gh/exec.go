package gh

import (
	"bytes"
	"context"
	"fmt"
	"os/exec"
)

func Run(ctx context.Context, args ...string) (string, error) {
	cmd := exec.CommandContext(ctx, "get-hubbed", args...)

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("get-hubbed %v: %w: %s", args, err, stderr.String())
	}

	return stdout.String(), nil
}
