// Calls Claude through the Anthropic Messages API and returns parsed JSON.
import { env, HttpError } from "./http.ts";

export async function askClaudeJSON<T>(opts: { system: string; prompt: string; maxTokens?: number }): Promise<T> {
  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": env("ANTHROPIC_API_KEY"),
      "anthropic-version": "2023-06-01",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: Deno.env.get("ANTHROPIC_MODEL") ?? "claude-sonnet-5-5",
      max_tokens: opts.maxTokens ?? 4000,
      system: opts.system,
      messages: [{ role: "user", content: opts.prompt }],
    }),
  });
  if (!response.ok) {
    throw new HttpError(502, `Claude request failed (${response.status}): ${await response.text()}`);
  }
  const data = await response.json();
  const text: string = (data.content ?? [])
    .filter((block: { type: string }) => block.type === "text")
    .map((block: { text: string }) => block.text)
    .join("");
  return parseJSON<T>(text);
}

/** Accepts plain JSON or JSON inside a ```json fence. */
export function parseJSON<T>(text: string): T {
  const fenced = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  const raw = (fenced ? fenced[1] : text).trim();
  const start = raw.search(/[\[{]/);
  if (start < 0) throw new HttpError(502, "Claude did not return JSON");
  return JSON.parse(raw.slice(start)) as T;
}
