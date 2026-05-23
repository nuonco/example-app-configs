#!/usr/bin/env python3
"""Demo: a small tool-using Claude agent that emits Langfuse traces.

Run via run.sh. Expects in env:
  LANGFUSE_HOST, LANGFUSE_PUBLIC_KEY, LANGFUSE_SECRET_KEY, ANTHROPIC_API_KEY
"""

import os
import sys
from datetime import datetime, timedelta, timezone

from anthropic import Anthropic
from langfuse import Langfuse
from langfuse.decorators import langfuse_context, observe


LANGFUSE_HOST = os.environ["LANGFUSE_HOST"]
ANTHROPIC_API_KEY = os.environ["ANTHROPIC_API_KEY"]
MODEL = os.environ.get("CLAUDE_MODEL", "claude-sonnet-4-6")

langfuse = Langfuse(
    host=LANGFUSE_HOST,
    public_key=os.environ["LANGFUSE_PUBLIC_KEY"],
    secret_key=os.environ["LANGFUSE_SECRET_KEY"],
)
anthropic_client = Anthropic(api_key=ANTHROPIC_API_KEY)


TOOLS = [
    {
        "name": "current_time",
        "description": "Returns the current UTC date and time as an ISO 8601 string.",
        "input_schema": {"type": "object", "properties": {}, "required": []},
    },
    {
        "name": "add_days",
        "description": "Adds a number of days to an ISO 8601 date and returns the resulting ISO date.",
        "input_schema": {
            "type": "object",
            "properties": {
                "iso_date": {"type": "string", "description": "Starting date in ISO 8601 format"},
                "days": {"type": "integer", "description": "Days to add (may be negative)"},
            },
            "required": ["iso_date", "days"],
        },
    },
    {
        "name": "knowledge_lookup",
        "description": "Look up canned facts about Langfuse, BYOC, and Nuon.",
        "input_schema": {
            "type": "object",
            "properties": {"topic": {"type": "string"}},
            "required": ["topic"],
        },
    },
]


@observe(name="tool")
def run_tool(name: str, args: dict) -> str:
    langfuse_context.update_current_observation(input={"tool": name, "args": args})

    if name == "current_time":
        result = datetime.now(timezone.utc).isoformat()
    elif name == "add_days":
        start = datetime.fromisoformat(args["iso_date"].replace("Z", "+00:00"))
        result = (start + timedelta(days=int(args["days"]))).isoformat()
    elif name == "knowledge_lookup":
        facts = {
            "langfuse": (
                "Langfuse is an open-source LLM observability and tracing platform. "
                "It captures traces, observations (LLM calls, retrievals, tool calls), "
                "and scores, then surfaces them in a web UI with cost, latency, and quality views."
            ),
            "byoc": (
                "Bring Your Own Cloud (BYOC) is a delivery model where the vendor's "
                "application is installed and operated inside the customer's own cloud account. "
                "Customers keep data sovereignty and the SaaS-like experience; vendors keep "
                "operational control via tools like Nuon."
            ),
            "nuon": (
                "Nuon (https://nuon.co) is a platform for installing and operating vendor "
                "applications inside customer cloud accounts. Vendors describe their app as "
                "Nuon TOML configs that reference Terraform modules, Helm charts, and Kubernetes "
                "manifests; Nuon's control plane drives installs across customer VPCs."
            ),
        }
        result = facts.get(
            args["topic"].lower().strip(),
            f"No canned facts indexed for '{args['topic']}'.",
        )
    else:
        result = f"Unknown tool: {name}"

    langfuse_context.update_current_observation(output=result)
    return result


@observe(name="agent-step", as_type="generation")
def call_claude(messages: list) -> object:
    langfuse_context.update_current_observation(
        input=messages, model=MODEL, metadata={"tools": [t["name"] for t in TOOLS]}
    )
    response = anthropic_client.messages.create(
        model=MODEL,
        max_tokens=2048,
        tools=TOOLS,
        messages=messages,
    )
    usage = {
        "input": response.usage.input_tokens,
        "output": response.usage.output_tokens,
    }
    langfuse_context.update_current_observation(
        output=[block.model_dump() for block in response.content],
        usage=usage,
    )
    return response


@observe(name="demo-agent")
def run_agent(prompt: str, max_steps: int = 8) -> str:
    langfuse_context.update_current_observation(input=prompt)
    messages = [{"role": "user", "content": prompt}]

    for step in range(max_steps):
        response = call_claude(messages)
        messages.append({"role": "assistant", "content": response.content})

        if response.stop_reason == "end_turn":
            text = "".join(b.text for b in response.content if b.type == "text")
            langfuse_context.update_current_observation(output=text)
            return text

        if response.stop_reason == "tool_use":
            tool_results = []
            for block in response.content:
                if block.type == "tool_use":
                    result = run_tool(block.name, dict(block.input))
                    tool_results.append(
                        {"type": "tool_result", "tool_use_id": block.id, "content": result}
                    )
            messages.append({"role": "user", "content": tool_results})
            continue

        # Any other stop_reason: bail out
        text = "".join(b.text for b in response.content if b.type == "text")
        langfuse_context.update_current_observation(output=text)
        return text

    return "agent hit max_steps without ending"


def main() -> int:
    prompt = (
        "You're answering a quick demo question. "
        "First, use current_time to get today's UTC date. "
        "Then use add_days to compute the date 100 days from now. "
        "Then use knowledge_lookup for the topics 'langfuse', 'byoc', and 'nuon'. "
        "Finally, write a tight 3-sentence summary that uses all of those facts together."
    )
    print(f"[demo] prompt:\n  {prompt}\n")

    try:
        answer = run_agent(prompt)
    finally:
        langfuse.flush()

    print(f"\n[demo] final answer:\n{answer}\n")
    print(f"[demo] traces sent to: {LANGFUSE_HOST}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
