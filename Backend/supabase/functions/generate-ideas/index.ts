// Writes fresh video ideas for an agent's Florida cities with Claude.
// Inputs: the agent's home city and service areas, niche, goals and month.
// Context: city traits, highlights, neighborhoods, this month's seasonal moments,
// real market stats when we have them, matching templates and what performs locally.
import { admin, readJSON, requireUser, serve, json } from "../_shared/http.ts";
import { askClaudeJSON } from "../_shared/claude.ts";

type Body = {
  city_id?: string;
  service_area_ids?: string[];
  niche?: string;
  goals?: string[];
  month?: number;
  count?: number;
};

type Idea = {
  title: string;
  hook: string;
  category: string;
  shots: string[];
  script: string;
  target_seconds: number;
  why_it_works: string;
  city_name: string;
};

const CATEGORIES = ["listingTour", "marketUpdate", "neighborhood", "mythBuster", "clientStory", "dayInLife", "openHouse"];

serve(async (req) => {
  const { user } = await requireUser(req);
  const body = await readJSON<Body>(req);
  const db = admin();
  const month = body.month ?? new Date().getMonth() + 1;
  const count = Math.min(Math.max(body.count ?? 10, 3), 15);

  const { data: profile } = await db.from("profiles")
    .select("name, niche, city_id, service_area_ids, goals, role, team_name")
    .eq("id", user.id).single();

  const cityIDs = [body.city_id ?? profile?.city_id, ...(body.service_area_ids ?? profile?.service_area_ids ?? [])]
    .filter((id): id is string => Boolean(id)).slice(0, 7);
  if (cityIDs.length === 0) cityIDs.push("tampa-hillsborough");

  const [{ data: cities }, { data: templates }, { data: moments }, { data: stats }, { data: performance }] = await Promise.all([
    db.from("cities").select("id, name, county, region, population, traits, highlights, neighborhoods").in("id", cityIDs),
    db.from("idea_templates").select("key, category, title, hook, script, any_of_traits, months").eq("active", true).limit(40),
    db.from("seasonal_moments").select("title, detail, hook, city_id, region, any_of_traits").contains("months", [month]).eq("active", true),
    db.from("market_stats").select("city_id, period, median_price, median_days_on_market, new_listings, active_listings")
      .in("city_id", cityIDs).order("period", { ascending: false }).limit(cityIDs.length * 2),
    db.from("city_idea_performance").select("city_id, category, posts, avg_views, leads").in("city_id", cityIDs),
  ]);

  const system = [
    "You write short form real estate video ideas for agents in Florida.",
    "Every idea must be specific to one of the agent's cities: name real places from the city data, the county, the season and local buyer questions.",
    "Only state facts that are in the provided data or are general Florida knowledge you are certain of. Never invent prices, statistics or events.",
    "If market stats are provided use them; otherwise tell the agent to fill in the numbers.",
    "Follow fair housing rules: describe places and amenities, never people or who should live somewhere. Point to official sources for schools.",
    "Scripts are spoken, 25 to 60 seconds, plain words, and end with a comment keyword in capital letters.",
    "Do not use em dashes.",
    `Return only JSON: {"ideas": [{"title", "hook", "category" (one of ${CATEGORIES.join(", ")}), "shots" (3 to 5), "script", "target_seconds", "why_it_works", "city_name"}]}.`,
  ].join("\n");

  const prompt = JSON.stringify({
    agent: { name: profile?.name, niche: body.niche ?? profile?.niche, goals: body.goals ?? profile?.goals, role: profile?.role },
    month,
    cities,
    seasonal_moments: moments,
    market_stats: stats,
    what_performs_here: performance,
    example_templates: templates,
    count,
    instructions: `Write ${count} ideas. At least half for the home city (${cityIDs[0]}), the rest spread across the other cities. Mix categories. Use at least 2 seasonal moments if any fit.`,
  });

  const result = await askClaudeJSON<{ ideas: Idea[] }>({ system, prompt, maxTokens: 6000 });
  const ideas = (result.ideas ?? []).filter((idea) => idea.title && idea.script).map((idea) => ({
    ...idea,
    category: CATEGORIES.includes(idea.category) ? idea.category : "neighborhood",
    target_seconds: Math.min(Math.max(Number(idea.target_seconds) || 35, 15), 90),
  }));

  const cityByName = new Map((cities ?? []).map((c: { id: string; name: string }) => [c.name, c.id]));
  if (ideas.length > 0) {
    await db.from("ideas").insert(ideas.map((idea) => ({
      profile_id: user.id,
      title: idea.title,
      hook: idea.hook,
      category: idea.category,
      shots: idea.shots,
      script: idea.script,
      target_seconds: idea.target_seconds,
      why_it_works: idea.why_it_works,
      city_id: cityByName.get(idea.city_name) ?? cityIDs[0],
      source: "ai",
    })));
  }

  return json({ ideas });
});
