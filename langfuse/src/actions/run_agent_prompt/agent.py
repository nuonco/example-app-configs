#!/usr/bin/env python3
"""Send a single user-supplied prompt to Claude and trace it in Langfuse.

Run via run.sh. Expects in env:
  LANGFUSE_HOST, LANGFUSE_PUBLIC_KEY, LANGFUSE_SECRET_KEY,
  ANTHROPIC_API_KEY, PROMPT, CLAUDE_MODEL (optional)
"""

import os
import sys

from anthropic import Anthropic
from langfuse import Langfuse
from langfuse.decorators import langfuse_context, observe


LANGFUSE_HOST = os.environ["LANGFUSE_HOST"]
ANTHROPIC_API_KEY = os.environ["ANTHROPIC_API_KEY"]
MODEL = os.environ.get("CLAUDE_MODEL", "claude-sonnet-4-6")
PROMPT = os.environ["PROMPT"]

langfuse = Langfuse(
    host=LANGFUSE_HOST,
    public_key=os.environ["LANGFUSE_PUBLIC_KEY"],
    secret_key=os.environ["LANGFUSE_SECRET_KEY"],
)
anthropic_client = Anthropic(api_key=ANTHROPIC_API_KEY)


@observe(name="prompt-call", as_type="generation")
def call_claude(prompt: str) -> str:
    langfuse_context.update_current_observation(
        input=prompt,
        model=MODEL,
        metadata={"action": "run_agent_prompt"},
    )
    response = anthropic_client.messages.create(
        model=MODEL,
        max_tokens=2048,
        messages=[{"role": "user", "content": prompt}],
    )
    text = "".join(b.text for b in response.content if b.type == "text")
    usage = {
        "input": response.usage.input_tokens,
        "output": response.usage.output_tokens,
    }
    langfuse_context.update_current_observation(output=text, usage=usage)
    return text


@observe(name="ad-hoc-prompt")
def run_prompt(prompt: str) -> str:
    langfuse_context.update_current_observation(input=prompt)
    answer = call_claude(prompt)
    langfuse_context.update_current_observation(output=answer)
    return answer


def main() -> int:
    print(f"[prompt] user prompt:\n  {PROMPT}\n")
    try:
        answer = run_prompt(PROMPT)
    finally:
        langfuse.flush()

    print(f"\n[claude] response:\n{answer}\n")
    print(f"[trace] sent to: {LANGFUSE_HOST}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
