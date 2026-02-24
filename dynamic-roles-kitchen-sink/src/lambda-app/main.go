package main

import (
	"context"
	"encoding/json"
	"os"
	"runtime"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

type response struct {
	Message       string  `json:"message"`
	Timestamp     string  `json:"timestamp"`
	InstallID     string  `json:"installId"`
	Request       request `json:"request"`
	Environment   env     `json:"environment"`
	Demonstration demo    `json:"demonstration"`
}

type request struct {
	Method   string `json:"method"`
	Path     string `json:"path"`
	SourceIP string `json:"sourceIp"`
}

type env struct {
	GoVersion    string `json:"goVersion"`
	Platform     string `json:"platform"`
	Architecture string `json:"architecture"`
	MemoryLimit  string `json:"memoryLimit"`
	FunctionName string `json:"functionName"`
	Region       string `json:"region"`
}

type demo struct {
	Purpose      string `json:"purpose"`
	DeployRole   string `json:"deployRole"`
	TeardownRole string `json:"teardownRole"`
	ActionRole   string `json:"actionRole"`
}

func handler(ctx context.Context, event events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	installID := os.Getenv("INSTALL_ID")
	if installID == "" {
		installID = "unknown"
	}

	resp := response{
		Message:   "Hello from dynamic-roles-kitchen-sink!",
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		InstallID: installID,
		Request: request{
			Method:   event.RequestContext.HTTP.Method,
			Path:     event.RequestContext.HTTP.Path,
			SourceIP: event.RequestContext.HTTP.SourceIP,
		},
		Environment: env{
			GoVersion:    runtime.Version(),
			Platform:     runtime.GOOS,
			Architecture: runtime.GOARCH,
			MemoryLimit:  os.Getenv("AWS_LAMBDA_FUNCTION_MEMORY_SIZE"),
			FunctionName: os.Getenv("AWS_LAMBDA_FUNCTION_NAME"),
			Region:       os.Getenv("AWS_REGION"),
		},
		Demonstration: demo{
			Purpose:      "IAM operation role demonstration",
			DeployRole:   "lambda-deploy-role (minimal creation permissions)",
			TeardownRole: "lambda-teardown-role (deletion-only permissions)",
			ActionRole:   "action-diagnostics-role (read-only inspection)",
		},
	}

	body, err := json.MarshalIndent(resp, "", "  ")
	if err != nil {
		return events.APIGatewayV2HTTPResponse{StatusCode: 500}, err
	}

	return events.APIGatewayV2HTTPResponse{
		StatusCode: 200,
		Headers: map[string]string{
			"Content-Type":                "application/json",
			"Access-Control-Allow-Origin": "*",
			"X-Install-ID":               installID,
		},
		Body: string(body),
	}, nil
}

func main() {
	lambda.Start(handler)
}
