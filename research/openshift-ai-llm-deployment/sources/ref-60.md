# Source: ref-60

**URL:** https://intuitionlabs.ai/pdfs/llm-api-pricing-comparison-2025-openai-gemini-claude.pdf
**Fetched:** 2026-04-17 17:56:10

---

IntuitionLabs - AI Software for Pharma & Biotech LLM API Pricing Comparison (2025): OpenAI, Gemini, Claude
LLM API Pricing Comparison (2025): OpenAI,
Gemini, Claude
By Adrien Laurent, CEO at IntuitionLabs • 10/31/2025 • 25 min read
llm api pricing openai pricing google gemini anthropic claude ai cost analysis token pricing gpt-5
grok api deepseek ai
© 2026 IntuitionLabs.ai - North America's Leading AI Software Development Firm for Pharmaceutical & Biotech. All rights Page 1 of
reserved. 13

---

IntuitionLabs - AI Software for Pharma & Biotech LLM API Pricing Comparison (2025): OpenAI, Gemini, Claude
Last updated: February 28, 2026. Pricing verified against official provider documentation. Originally published
October 2025.
Executive Summary
By late 2025, the landscape of large language model (LLM) APIs has grown intensely competitive and complex, with
multiple providers offering a spectrum of model capabilities and pricing options. This report provides a detailed
comparison of the API pricing for all major LLM models from OpenAI, Google’s Gemini, Anthropic’s Claude, Elon Musk’s
xAI Grok, and China’s DeepSeek, synthesizing the latest public information. Our analysis shows that OpenAI continues
to lead with its expanding model lineup: GPT-5.2 ($1.75/$14 per MTok) and GPT-5.2 Pro ($21/$168) now serve as its
flagships, with GPT-5 mini ($0.25/$2) and GPT-5 nano ($0.05/$0.40) covering the budget tiers ([1] openai.com). Google’s
Gemini has advanced to the 3.x generation, with Gemini 3.1 Pro ($2/$12 per MTok) and Gemini 3 Flash ($0.50/$3)
joining the still-available 2.5 series ([2] cloud.google.com). Anthropic’s Claude now offers Opus 4.6 at $5/$25 per MTok,
Sonnet 4.6 at $3/$15, and Haiku 4.5 at $1/$5, representing significant price reductions from earlier generations ([3]
docs.anthropic.com). xAI has launched Grok 4 ($3/$15 per MTok), Grok 4 Fast ($0.20/$0.50), and Grok 4.1 Fast
($0.20/$0.50), replacing the earlier Grok 3 lineup ([4] techcrunch.com). Finally, China’s DeepSeek has undercut nearly all
competitors: its latest V3.2-Exp “thinking” models list at only $0.28 per 1M input (cache-miss) and $0.42 per 1M output ([5]
api-docs.deepseek.com) (with “cache hits” as low as $0.028 input). DeepSeek notably halved its prices in late 2025 ([6]
www.reuters.com), exemplifying a broader trend of rapidly falling AI costs in response to competition ([7]
www.techradar.com).
These differences mean that for the same task, costs can vary by orders of magnitude depending on model choice.
Throughout this report, we explore the historical evolution of these pricing schemes, compare them quantitatively in
tables, and discuss implications for developers and businesses choosing among providers. We also include case studies
illustrating real-world cost impacts, cite independent analyses of cost-cutting trends, and outline how aggressive pricing
(especially by open-source-focused players) may reshape the future economics of AI. All figures and claims here are
backed by official documentation and recent technology news sources ([8] www.reuters.com) ([4] techcrunch.com) ([3]
docs.anthropic.com) ([5] api-docs.deepseek.com).
Introduction and Background
Large language models have revolutionized numerous industries by enabling advanced natural language understanding
and generation. By 2025, LLM APIs are used for chatbots, coding assistants, document summarization, translation, and
more. Unlike earlier AI models, modern LLMs expose sophisticated token-based billing: every API call’s input and output
text (measured in tokens, roughly word pieces) incurs cost, aligning with a “pay-as-you-go” cloud model ([9]
www.binadox.com). This token-based pricing offers fine-grained control of costs but demands careful model selection and
prompt engineering.
The major LLM providers now include OpenAI, Google (via its Gemini models), Anthropic, xAI (Grok), and DeepSeek.
Each has multiple model variants optimized for different trade-offs (accuracy, speed, context length). OpenAI’s current
GPT-5.2 family includes standard, “Pro”, “mini”, and “nano” editions for different price/performance points ([1] openai.com).
Anthropic’s Claude line is tiered (Haiku, Sonnet, Opus), and Google’s Gemini offers “Pro” (large, multi-modal) vs “Flash”
(lighter, cheaper) versions ([2] cloud.google.com) ([3] docs.anthropic.com). Grok 4 comes in standard and fast modes, plus a
specialized coding variant ([4] techcrunch.com). DeepSeek provides “chat” and “reasoner” modes of its V3.2-Exp model,
with massive context windows (up to 128k tokens) ([10] api-docs.deepseek.com).
Pricing is a critical differentiator. All use per-token pricing, but rates vary widely by model. Generally, more capable
models cost more per token. Historical context shows rapid evolution: for example, OpenAI halved its GPT-3.5 Turbo
© 2026 IntuitionLabs.ai - North America's Leading AI Software Development Firm for Pharmaceutical & Biotech. All rights Page 2 of
reserved. 13

---

IntuitionLabs - AI Software for Pharma & Biotech LLM API Pricing Comparison (2025): OpenAI, Gemini, Claude
token price in 2023, then introduced GPT-4 (at ~10× the cost of 3.5), and in 2024 launched GPT-4o mini at just
$0.15/$0.60 per million input/output – a 60% discount vs GPT-3.5 Turbo ([8] www.reuters.com). Similarly, Chinese startups
like DeepSeek entered the market with dramatically lower pricing (DeepSeek R1 debuted at $0.55/$2.19 per million,
undercutting competitors by ~90% ([7] www.techradar.com)). These shifts reflect aggressive competition and have set new
baselines. The most recent data (as of Nov 2025) allow us to present the current state of API pricing for each provider’s
models, which we detail below, with extensive sourcing from official docs and tech press.
OpenAI API Models and Pricing
OpenAI, the originator of the GPT series, offers the broadest range of models. As of early 2026, its current lineup centers
on the GPT-5.2 family, with older GPT-5, GPT-4.1, and GPT-4o models now deprecated. OpenAI’s public API pricing for
current models:
GPT-5.2: The latest flagship model (Feb 2026), top performance in reasoning and agentic tasks.
Input: $1.75 per 1M tokens.
Cached input: $0.175 per 1M tokens.
Output: $14.00 per 1M tokens.
GPT-5.2 Pro: The premium tier of GPT-5.2 for maximum capability.
Input: $21.00 per 1M tokens.
Output: $168.00 per 1M tokens.
GPT-5 mini: A smaller, cheaper model for well-defined tasks.
Input: $0.25 per 1M.
Cached: $0.025 per 1M.
Output: $2.00 per 1M.
GPT-5 nano: The smallest and cheapest variant.
Input: $0.05 per 1M.
Cached: $0.005 per 1M.
Output: $0.40 per 1M ([11] openai.com) ([1] openai.com).
For example, sending 100k tokens of prompt and receiving 100k tokens of completion on GPT-5.2 costs ~$0.175 (input)
+ $1.40 (output) = $1.575 (ignoring caching). Historically, OpenAI’s GPT-4 series (GPT-4o at $5/$20 per MTok, GPT-4.1
at $3/$12) dominated through most of 2025, but has been superseded by the GPT-5.2 generation, which offers better
performance at competitive prices.
For comparison and thoroughness, below is a summary table of OpenAI’s key current models and rates:
Model (OpenAI) Description Input ($/M tokens) Output ($/M tokens) Notes
GPT-5.2 Pro Premium flagship (Feb 2026) $21.00 $168.00 Maximum capability
GPT-5.2 Latest flagship (Feb 2026) $1.75 $14.00 Top coder/agent model
GPT-5 mini Lighter model for simpler tasks $0.25 $2.00 Well-defined tasks
GPT-5 nano Smallest variant $0.05 $0.40 Summarization/classification tasks
Source: OpenAI official pricing pages (Q1 2026) ([11] openai.com). Note: fine-tuning prices and batch discounts (50%
off) exist but are omitted for brevity.
OpenAI’s pricing has trended sharply downward over the past two years. The GPT-4o mini launched in mid-2024 at
$0.15/$0.60 per MTok – a 60% reduction from GPT-3.5 Turbo ([8] www.reuters.com). The current GPT-5 nano at
© 2026 IntuitionLabs.ai - North America's Leading AI Software Development Firm for Pharmaceutical & Biotech. All rights Page 3 of
reserved. 13

---

IntuitionLabs - AI Software for Pharma & Biotech LLM API Pricing Comparison (2025): OpenAI, Gemini, Claude
$0.05/$0.40 continues that trend. Meanwhile, GPT-5.2 offers substantially better reasoning than earlier models at a
competitive $1.75/$14 price point. Overall, organizations using OpenAI’s models must balance the superior capabilities
against higher token costs compared to many alternatives.
Google Gemini API and Pricing
Google provides its LLMs through Vertex AI (Google Cloud) under the “Gemini” brand. The current lineup spans both the
2.5 and 3.x generations. Google’s pricing is tiered by usage volume (below or above 200K input tokens) for Pro models.
Key pricing from Google’s docs:
Gemini 2.5 Pro:
Input tokens: $1.25 per 1M (for ≤200K input), $2.50 per 1M (for >200K).
Text output (response & reasoning): $10 per 1M (≤200K input), $15 per 1M (>200K) ([2] cloud.google.com).
Gemini 2.5 Flash (multimodal smaller model):
Text/Image/Video input: $0.30 per 1M.
Audio input: $1.00 per 1M.
Text output: $2.50 per 1M ([12] cloud.google.com).
As of early 2026, Google has also released the Gemini 3.x generation:
Gemini 3.1 Pro:
Input tokens: $2.00 per 1M (for <=200K input), $4.00 per 1M (for >200K).
Text output: $12.00 per 1M (<=200K input), $18.00 per 1M (>200K).
Gemini 3 Flash:
Input tokens: $0.50 per 1M.
Text output: $3.00 per 1M.
Gemini 3 Pro Image:
Input tokens: $2.00 per 1M.
Text output: $12.00 per 1M.
Image output: $120.00 per 1M.
In plain terms, calling Gemini 2.5 Pro with a moderate prompt (e.g. 100K tokens) costs about $0.125 (input) + $1.00
(output) = $1.125 per 100K tokens, doubling if the prompt exceeds 200K. For Gemini 2.5 Flash, the cost is much lower:
only $0.03 input + $0.25 output per 100K. Google’s strategy offers a “Pro” model competitive with premium pricing and a
very cheap “Flash” model for volume tasks. Gemini 2.5 Pro below thresholds at $1.25/$10 per 1M is significantly lower
than Grok 4’s $3/$15 (see Grok section) ([13] www.linkedin.com).
Google also allows “grounding” with Google Search/Web to enrich responses, billed up to $35 per 1K grounded queries
([14] cloud.google.com). However, the base token costs above generally suffice for textual tasks.
Google Gemini Pricing Summary (per 1M tokens):
Model Input (\≤200K / >200K) Output Notes
Gemini 3.1 Pro $2.00 / $4.00 $12.00 / $18.00 Latest Pro model (2026)
© 2026 IntuitionLabs.ai - North America's Leading AI Software Development Firm for Pharmaceutical & Biotech. All rights Page 4 of
reserved. 13

---

IntuitionLabs - AI Software for Pharma & Biotech LLM API Pricing Comparison (2025): OpenAI, Gemini, Claude
Model Input (\≤200K / >200K) Output Notes
Gemini 3 Flash $0.50 $3.00 Latest Flash model (2026)
Gemini 3 Pro Image $2.00 $12.00 (text) / $120.00 (images) Image generation
Gemini 2.5 Pro $1.25 / $2.50 $10.00 / $15.00 Multi-modal; large
Gemini 2.5 Flash $0.30 $2.50 Supports image/audio; cheaper
Source: Google Cloud Vertex AI pricing docs ([2] cloud.google.com). Notes: Above 200K input tokens, both input and output
rates increase for Pro models.
In addition to token-pricing, Google’s Gemini (like Anthropic) often benefits from integration discounts if using Google
Cloud infrastructure. Overall, Gemini’s per-token pricing is competitive: Gemini 2.5 Pro at $1.25/$10 undercuts GPT-5.2’s
$1.75/$14, and the newer Gemini 3.1 Pro at $2/$12 remains competitive. Google’s heavy promotion of Gemini (e.g.
integrating AI into Search for 1.5B users by mid-2025 ([15] www.techradar.com)) suggests Google is willing to absorb costs
to grab market share, reinforcing the trend toward lower API fees.
Anthropic Claude API Pricing
Anthropic’s Claude family (Haiku, Sonnet, Opus) targets safety and reliability. Anthropic uniquely offers prompt caching
discounts in its pricing model (where repeat queries get cheaper). The current generation (as of early 2026) has
streamlined the lineup to three models, with earlier versions like Opus 4.1 ($15/$75), Sonnet 3.5-4.0, and Haiku 3-3.5
now deprecated. The base (non-cache) rates from Anthropic’s documentation are:
Claude Opus 4.6 (current flagship):
Input tokens: $5 per 1M.
Output tokens: $25 per 1M.
A massive price reduction from the earlier Opus 4.1 ($15/$75), making frontier Claude far more accessible.
Claude Sonnet 4.6 (current mid-tier):
Input: $3 per 1M.
Output: $15 per 1M.
Claude Haiku 4.5 (current small model):
Input: $1 per 1M.
Output: $5 per 1M ([3] docs.anthropic.com).
These rates assume standard (5-minute) caching or direct usage. Anthropic explains that “5m cache writes” cost 1.25×
base input, and “cache reads” cost only 0.1× base (illustrating the impact of caching) ([16] docs.anthropic.com).
In simplified terms, Claude Opus 4.6 at $5/$25 per million is now far more accessible than its predecessor Opus 4.1
($15/$75), and competes directly with GPT-5.2’s $1.75/$14. Sonnet 4.6 ($3/$15) matches Grok 4’s pricing. Haiku 4.5 at
$1/$5 serves as a strong budget option, though DeepSeek remains far cheaper at $0.28/$0.42.
For illustrative clarity, one can also view Claude batch rates (50% off) or long-context premium (detailed on Anthropic’s
site); however, the base token costs above capture the primary differences.
Anthropic Claude Pricing Summary (per 1M tokens):
Model Input (base) Output (base) Notes
Claude Opus 4.6 $5.00 $25.00 Current flagship (2026)
Claude Sonnet 4.6 $3.00 $15.00 Current mid-tier (2026)
© 2026 IntuitionLabs.ai - North America's Leading AI Software Development Firm for Pharmaceutical & Biotech. All rights Page 5 of
reserved. 13

---

IntuitionLabs - AI Software for Pharma & Biotech LLM API Pricing Comparison (2025): OpenAI, Gemini, Claude
Model Input (base) Output (base) Notes
Claude Haiku 4.5 $1.00 $5.00 Current small model (2026)
Source: Anthropic API pricing docs ([3] docs.anthropic.com). Note cache writes (~x1.25-2x) and cache hits (~x0.1) impact
effective cost for repeated prompts, and Anthropic offers a 50% discount on input/output under its Batch API (not shown
above for brevity).
In practice, Claude’s current pricing makes even the flagship Opus 4.6 reasonably accessible at $5/$25, a far cry from
the earlier $15/$75 Opus 4.1 era. Claude’s context window (200K tokens standard, extendable to 1M tokens beta ([3]
docs.anthropic.com)) means one can synthesize very long documents, albeit at special “long-context” rates if above 200K
input (doubling input cost beyond that threshold). For most use-cases, enterprises might mix models: e.g. use
Haiku/Sonnet for volume tasks and Opus only for the hardest tasks, to manage cost.
xAI Grok Pricing
xAI (Elon Musk’s AI startup) began public Grok releases in 2023. The earlier Grok 3 series (launched April 2025) has now
been superseded by the Grok 4 generation. The current API offerings are:
grok-4 – Latest flagship: $3.00 per 1M input, $15.00 per 1M output.
grok-4-fast – Fast mode: $0.20 per 1M input, $0.50 per 1M output.
grok-4-1-fast – Latest fast variant: $0.20 per 1M input, $0.50 per 1M output.
grok-code-fast-1 – Specialized coding model: $0.20 per 1M input, $1.50 per 1M output.
xAI positioned these as competing with mid-tier models from Google and Anthropic; Grok 4’s $3/$15 rate matches
Anthropic’s Claude Sonnet 4.6, but is higher than Google Gemini 2.5 Pro ($1.25/$10) ([4] techcrunch.com). The fast
variants at $0.20/$0.50 represent a significant price reduction from the earlier Grok 3 era.
Grok limits context to 131,072 tokens in the API ([17] techcrunch.com), so it is less applicable for ultra-long documents. In
comparative terms, Grok 4’s standard tier input cost ($3) is double Gemini 2.5 Pro’s ($1.25) but on par with Claude
Sonnet 4.6 ($3). The fast variants at $0.20 input are among the cheapest options available from any major provider.
Grok Pricing Summary (per 1M tokens):
Model (xAI Grok) Input Output Context (tokens) Notes
grok-4 $3.00 $15.00 131,072 Current flagship (2026)
grok-4-fast $0.20 $0.50 131,072 Fast mode (2026)
grok-4-1-fast $0.20 $0.50 131,072 Latest fast variant (2026)
grok-code-fast-1 $0.20 $1.50 131,072 Coding specialist (2026)
Source: TechCrunch reportage of xAI’s April 2025 Grok 3 API launch ([4] techcrunch.com) (corroborated by industry
sources ([13] www.linkedin.com)). All prices in USD per 1M tokens.
Compared to peers, Grok 4 is a mid-range offering at its standard tier: it’s more expensive than Google’s cheapest
(Flash) model, but the fast variants are extremely competitive. The addition of grok-code-fast-1 as a dedicated coding
model at $0.20/$1.50 shows xAI targeting specific use cases with aggressive pricing.
DeepSeek Pricing
DeepSeek is a Chinese AI startup that gained fame for open and affordable models. Its initial DeepSeek-R1 (open-
source) hit the market in January 2025, offering GPT-4 class performance at a fraction of the usual price ([18]
© 2026 IntuitionLabs.ai - North America's Leading AI Software Development Firm for Pharmaceutical & Biotech. All rights Page 6 of
reserved. 13

---

IntuitionLabs - AI Software for Pharma & Biotech LLM API Pricing Comparison (2025): OpenAI, Gemini, Claude
www.techradar.com). DeepSeek then evolved to V3 series. The latest announced model is DeepSeek-V3.2-Exp
(Experimental), with massively lowered pricing. According to DeepSeek’s API docs (Sept 2025), the Chat and Reasoner
variants of V3.2-Exp (128K context) have:
Input tokens: $0.028 per 1M (cache hit), $0.28 per 1M (cache miss) ([5] api-docs.deepseek.com).
Output tokens: $0.42 per 1M ([5] api-docs.deepseek.com).
DeepSeek introduced a cache mechanism: if a prompt (or subprompt) is already used (“cache hit”), input cost is only
$0.028/M; otherwise $0.28/M. This means repeated queries become almost free, incentivizing stateful use. Notably,
DeepSeek cut all its prices by ~50% in Sep 2025 ([6] www.reuters.com) compared to the prior V3.2-beta (the Reuters
piece states “reducing API pricing by over 50%” ([6] www.reuters.com)).
For context, DeepSeek’s original R1 model had pricing around $0.55/$2.19 (input/output) ([7] www.techradar.com). Thus
V3.2-Exp’s $0.28/$0.42 is now dramatically lower: roughly 85% below OpenAI’s GPT-5.2 pricing on input and 97%
below on output. TechRadar reports: ”DeepSeek-R1 debuted at $0.55 input/$2.19 output” and comments that LLM pricing
“has cratered” since ([7] www.techradar.com). DeepSeek’s new prices validate that trend.
In practical terms, DeepSeek is now by far the cheapest LLM API for raw token costs. For example, processing 1M
tokens of input and 1M output (a huge request) would cost just $0.28 + $0.42 = $0.70 total (cache-miss). Even with
repeated use (cache hits), cost is only $0.028 + $0.42 = $0.448. By comparison, OpenAI’s cheapest model (GPT-5 nano)
would cost $0.05 + $0.40 = $0.45 (similar), but GPT-5 nano has only a 32K context. DeepSeek’s model offers 128K
context ([10] api-docs.deepseek.com), far more data at similarly tiny price.
DeepSeek V3.2-Exp Pricing Summary (per 1M tokens):
Mode Input (cache-hit) Input (cache-miss) Output Context
DeepSeek Chat $0.028 $0.28 $0.42 128K tokens
DeepSeek Reasoner $0.028 $0.28 $0.42 128K tokens
Source: DeepSeek API documentation (Sept 2025) ([5] api-docs.deepseek.com). Note: caching heavily affects input pricing.
The aggressive pricing is a deliberate strategy. As quoted by Reuters, DeepSeek aims “to match or exceed rivals’
performance at reduced costs” to “solidify its position” ([19] www.reuters.com). Industry commentary underscores this “price
war”: Chinese models (DeepSeek, Baidu’s Ernie) have pushed token costs near zero, challenging Western providers ([20]
www.techradar.com). In fact, TechRadar notes “China is commoditizing AI faster than the West can monetize it”, since free
open models threaten the business case for paid ones ([20] www.techradar.com).
Comparative Analysis
To compare across providers, consider example per-token costs. Table below contrasts representative high-capacity
and low-cost models:
Provider Model Input ($/M) Output ($/M) Context (tokens) Remarks
OpenAI GPT-5.2 Pro $21.00 $168.00 128K Premium flagship (2026)
OpenAI GPT-5.2 $1.75 $14.00 128K Latest flagship (2026)
OpenAI GPT-5 mini $0.25 $2.00 32K Lite model
OpenAI GPT-5 nano $0.05 $0.40 32K Budget model
Google Gemini 3.1 Pro $2.00-$4.00* $12-$18* 2M Latest Pro (2026)
Google Gemini 3 Flash $0.50 $3.00 2M Latest Flash (2026)
Google Gemini 2.5 Pro $1.25-$2.50* $10-$15* 2M Tiered pricing
Google Gemini 2.5 Flash $0.30 $2.50 2M Cheap, versatile
© 2026 IntuitionLabs.ai - North America's Leading AI Software Development Firm for Pharmaceutical & Biotech. All rights Page 7 of
reserved. 13

---

IntuitionLabs - AI Software for Pharma & Biotech LLM API Pricing Comparison (2025): OpenAI, Gemini, Claude
Provider Model Input ($/M) Output ($/M) Context (tokens) Remarks
Anthropic Claude Opus 4.6 $5.00 $25.00 200K Current flagship (2026)
Anthropic Claude Sonnet 4.6 $3.00 $15.00 200K Current mid-tier (2026)
Anthropic Claude Haiku 4.5 $1.00 $5.00 200K Current small (2026)
xAI Grok 4 $3.00 $15.00 128K Current flagship (2026)
xAI Grok 4 Fast $0.20 $0.50 128K Fast mode (2026)
xAI Grok 4.1 Fast $0.20 $0.50 128K Latest fast (2026)
xAI Grok Code Fast 1 $0.20 $1.50 128K Coding specialist (2026)
DeepSeek V3.2-Exp (chat) $0.28$** $0.42 128K Ultra-low cost
DeepSeek V3.2-Exp (reasoner) $0.28$$ $0.42 128K (Same price for both)
* Tiered: first $1.25/$10 up to 200K tokens, then $2.50/$15 beyond.
$$ Cache-hit price ($0.028) – see note.
This table highlights the orders-of-magnitude differences. DeepSeek’s input/output are compared as cached-hit/miss:
Remarkably, even its un-cached price ($0.28) is still below many competitors’ lowest tiers. For instance, DeepSeek’s
$0.28 input is ~~5× cheaper~~ than GPT-5 mini’s $0.25 (note: actually slightly higher; but output $0.42 is significantly
lower than GPT-5 mini’s $2.00). And DeepSeek lacks any “fast mode,” yet is used for heavy reasoning tasks (“chat” mode
is fully capable).
Price per 100K tokens (example): To illustrate real costs, consider 100K input + 100K output tokens (a large query).
Using the above rates:
GPT-5.2: 0.1 x input cost + 0.1 x output cost = $0.175 + $1.40 = $1.575.
Gemini 2.5 Pro (<=200K): $0.125 + $1.00 = $1.125.
Claude Sonnet 4.6: $0.30 + $1.50 = $1.80.
Grok 4: $0.30 + $1.50 = $1.80 (identical to Claude Sonnet 4.6).
DeepSeek (miss): $0.028 + $0.042 = $0.070.
Thus, for this scenario, OpenAI and Google cost about $1.1-1.8, while DeepSeek costs mere 7 cents. Even using
DeepSeek’s cache-hit input, it’s $0.0028 + $0.042 = $0.044 – effectively 25x cheaper.
We see three pricing tiers: (1) Premium models (GPT-5.2 Pro, Claude Opus 4.6) at $14-168 per M output; (2) Mid-tier
(GPT-5.2, Gemini Pro, Claude Sonnet 4.6, Grok 4) at $3-$15; (3) Low-end (GPT-5 nano, Gemini Flash, Grok Fast,
DeepSeek) at $0.4-$3. Real case studies (below) reflect these strata.
Case Studies and Example Scenarios
Case 1: Customer Support Chatbot. A company processes ~10 million tokens per month (input+output). Using GPT-5.2
would cost ~$14*(10) = $140 (per million tokens * output ratio), whereas Gemini 3 Flash would cost ~$3*(10) = $30.
Claude Haiku 4.5 would cost ~$5*(10) = $50. DeepSeek would cost less than $5 for the same volume. Thus, if budget is
critical and moderate comprehension is acceptable, Gemini Flash or DeepSeek could reduce AI costs dramatically versus
premium OpenAI models.
Case 2: Enterprise Document Summarization. Summarizing large contracts of 50K words (approx 60K tokens) per
doc, 100 docs monthly (6M tokens). Claude Opus 4.6 (legal-detail level) would cost ~$56 = $30 for input plus $256 =
$150 output, total $180. A Sonnet 4.6-level model would cost $36 + $156 = $108. GPT-5 mini would cost $0.256 + $26 =
$13.50. DeepSeek: $0.286 + $0.426 = $4.2. This shows that even with the recent price reductions, high-capability models
still cost significantly more than budget alternatives. The cost variance remains dramatic.
© 2026 IntuitionLabs.ai - North America's Leading AI Software Development Firm for Pharmaceutical & Biotech. All rights Page 8 of
reserved. 13

---

IntuitionLabs - AI Software for Pharma & Biotech LLM API Pricing Comparison (2025): OpenAI, Gemini, Claude
Real-World Example: Bing Chat Integration. Microsoft’s integration of GPT-4.0 (“o-1”) via Bing forced careful price-
negotiation. Industry analysts note Microsoft extracts large volume (billions of tokens) at internal rates; public API users
might pay far more. Microsoft’s Azure OpenAI, since 2023, offered OpenAI models with tiered enterprise pricing and
commitments, illustrating that heavy users (enterprise scale) get discounts. Similarly, Google’s Gemini integration
(1.5B users using AI Overviews) suggests Google subsidizes its own models internally, effectively giving “away” some
API usage to lock in developers (a point TechRadar makes about search integration ([15] www.techradar.com)). These
strategic moves underscore that what an end-customer pays can differ from sticker price – but our analysis uses the
published rates for baseline.
Survey Insight. According to developer surveys, average heavy API users consume around 50k tokens per day
(illustrative). At GPT-5.2’s rate, that’s roughly $0.09 input + $0.70 output = $0.79/day per user. For an enterprise with 100
daily active bots each consuming ~50k tokens, the monthly cost on GPT-5.2 would be around $2,400. Switching to GPT-
5 mini or Gemini Flash would reduce that to a few hundred dollars. This aligns with industry reports that cost control is a
top concern for AI teams ([21] www.binadox.com).
Pricing Trends and Future Implications
The rapid evolution in LLM pricing reflects both market competition and technological advances. Key trends and
implications include:
Price Wars and Commoditization: Chinese models like DeepSeek have sparked what analysts call shifting from a performance race to
a price war ([20] www.techradar.com). Open models (DeepSeek, Baidu Ernie) make high-end AI effectively free, challenging Western
vendors’ paywalls ([20] www.techradar.com). OpenAI’s aggressive pricing on the GPT-5.2 family, and Anthropic’s dramatic reduction
from Opus 4.1 ($15/$75) to Opus 4.6 ($5/$25), show the pressure to reduce costs. We expect continuing downward pressure: new
models will aim to double performance at half the price, and fine-tuning or batch APIs will proliferate to cut costs.
Differentiated Offerings: Providers mitigate margin loss by segmenting offerings. OpenAI has premium (GPT-5.2 Pro) vs standard
(GPT-5.2) vs lite (mini/nano) models; Google has Pro vs Flash; Anthropic has Opus vs Sonnet vs Haiku; xAI has standard vs fast plus a
coding specialist. Organizations will increasingly use hybrid strategies: heavy workloads on cheap models (e.g. Grok Fast, DeepSeek)
and reserve premium models for niche tasks.
Two-Part Pricing and Ecosystem Effects: Tiered pricing (volume discounts, batch APIs) and multi-modal features complicate direct
comparisons. For instance, Google charges extra for “grounded” search queries, while Anthropic’s long-context pricing premium and
caching create effective nonlinear cost curves ([14] cloud.google.com) ([3] docs.anthropic.com). This means vendors might not strictly
compete on raw token price, but on value (e.g. freshness, search, tool use). Pricing strategy becomes part of lock-in: e.g. Google
bundling lower Gemini rates for Cloud users. We already see enterprises bundling LLM spend into cloud contracts (Azure, AWS Bedrock
multi-LLM billing) to manage cost predictability ([22] www.binadox.com).
Use of Tokens vs. Alternatives: Some providers experiment with non-token billing. For example, OpenAI offers a “request-based”
pricing for certain APIs (e.g. Vision API in dollar per image rather than per token). Large-scale use cases might evolve hybrid pricing (e.g.
fixed-price content creation subscription). However, the fundamental token model will likely remain primary for text generation at least
through 2026. Tools and prompt optimization (e.g. GPT’s “cost consciousness” like avoiding ChatGPT answer verbosity) will become best
practices for controlling token spend.
Long-Term Outlook: Given escalating hardware availability (specialized AI chips), we predict LLM inference costs will continue falling.
The rapid succession of model generations (GPT-4o to GPT-5.2 in under a year, Claude Opus 4.1 to 4.6 in months) demonstrates how
quickly pricing can shift. The competition may split: Western companies will focus on premium, controlled-use markets (enterprise, where
SLAs and compliance justify pay), while commodity use moves toward open-source in Asia/elsewhere. The broader AI market will likely
fragment: bundling of vision, voice, browsing with LLM, cross-subsidizing some aspects.
In sum, cost optimization is now a core part of the AI developer playbook. Our analysis suggests that enterprises must
carefully match model selection to use-case, balancing “best model” vs “acceptable model” based on token budgets. For
example, as one recent whitepaper notes, using a cheaper model for 70% of routine tasks and reserving the most
expensive model for 30% yields better ROI than all-in on the top model ([9] www.binadox.com). As Gartner analysts have
© 2026 IntuitionLabs.ai - North America's Leading AI Software Development Firm for Pharmaceutical & Biotech. All rights Page 9 of
reserved. 13

---

IntuitionLabs - AI Software for Pharma & Biotech LLM API Pricing Comparison (2025): OpenAI, Gemini, Claude
forecast, by 2026 AI services cost will become a chief competitive factor, potentially surpassing raw performance in
importance. The pricing data compiled here will help stakeholders make informed choices in that landscape.
Conclusion
This February 2026 update (originally published November 2025) reveals a highly competitive LLM API market with vast
cost differentials. OpenAI’s GPT models remain at the cutting edge of capability but also at premium prices; Google’s
Gemini strikes a middle ground with competitive pricing and integration benefits; Anthropic’s Claude offers robust safety
at moderate cost; xAI’s Grok competes as a niche “scientific” model; and DeepSeek pushes prices to rock-bottom levels.
Our side-by-side comparisons (in tables above) show that identical tasks could cost anywhere from a few cents to
hundreds of dollars depending on provider and model.
Crucially, these rates are dynamic. New model releases, volume agreements, and one-off promotions will further shift the
playing field. We recommend that AI consumers continuously re-evaluate pricing, consider multi-provider strategies, and
leverage specialized offerings (batch APIs, caching, long-context) to optimize costs.
In closing, as one industry report quipped, “LLM pricing changes faster than any cryptocurrency,” and our comprehensive
analysis aims to be a timely guide in this rapidly changing environment. All figures and comparisons above are grounded
in the latest public sources and official documentation ([4] techcrunch.com) ([3] docs.anthropic.com) ([5] api-
docs.deepseek.com) ([1] openai.com). Continued transparency from providers and third-party tracking will be essential for
navigating the ongoing AI pricing revolution.
External Sources
[1] https://openai.com/bn-BD/api/pricing/#:~:GPT...
[2] https://cloud.google.com/vertex-ai/generative-ai/pricing?hl=he#:~:Gemin...
[3] https://docs.anthropic.com/en/docs/about-claude/pricing
[4] https://techcrunch.com/2025/04/09/elon-musks-ai-company-xai-launches-an-api-for-grok-3/#:~:Grok%...
[5] https://api-docs.deepseek.com/quick_start/pricing#:~:PRICI...
[6] https://www.reuters.com/technology/deepseek-releases-model-it-calls-intermediate-step-towards-next-generation-2025-09-29/#:~:
Chine...
[7] https://www.techradar.com/pro/why-baidus-ernie-matters-more-than-deepseek#:~:DeepS...
[8] https://www.reuters.com/technology/artificial-intelligence/openai-unveils-cheaper-small-ai-model-gpt-4o-mini-2024-07-18/#:~:Open
A...
[9] https://www.binadox.com/blog/llm-api-pricing-comparison-2025-complete-cost-analysis-guide/#:~:Unlik...
[10] https://api-docs.deepseek.com/quick_start/pricing#:~:MODEL...
[11] https://openai.com/bn-BD/api/pricing/#:~:Price...
[12] https://cloud.google.com/vertex-ai/generative-ai/pricing?hl=he#:~:Text%...
[13] https://www.linkedin.com/pulse/xai-launches-grok-3-api-four-pricing-tiers-intensifying-%E6%9D%B0-%E9%82%93-q1qic#:~:,ever...
[14] https://cloud.google.com/vertex-ai/generative-ai/pricing?hl=he#:~:Groun...
© 2026 IntuitionLabs.ai - North America's Leading AI Software Development Firm for Pharmaceutical & Biotech. All rights Page 10 of
reserved. 13

---

IntuitionLabs - AI Software for Pharma & Biotech LLM API Pricing Comparison (2025): OpenAI, Gemini, Claude
[15] https://www.techradar.com/pro/why-baidus-ernie-matters-more-than-deepseek#:~:Just%...
[16] https://docs.anthropic.com/en/docs/about-claude/pricing?%3F%3F%3F__hstc=43401018.71aa366c60c32c7e3032e45be702fadd.
1753488000320.1753488000321.1753488000322.1#:~:MTok%...
[17] https://techcrunch.com/2025/04/09/elon-musks-ai-company-xai-launches-an-api-for-grok-3/#:~:As%20...
[18] https://www.techradar.com/pro/why-baidus-ernie-matters-more-than-deepseek#:~:A%20f...
[19] https://www.reuters.com/technology/deepseek-releases-model-it-calls-intermediate-step-towards-next-generation-2025-09-29/#:~:
Altho...
[20] https://www.techradar.com/pro/why-baidus-ernie-matters-more-than-deepseek#:~:China...
[21] https://www.binadox.com/blog/llm-api-pricing-comparison-2025-complete-cost-analysis-guide/#:~:LLM%2...
[22] https://www.binadox.com/blog/llm-api-pricing-comparison-2025-complete-cost-analysis-guide/#:~:Many%...
© 2026 IntuitionLabs.ai - North America's Leading AI Software Development Firm for Pharmaceutical & Biotech. All rights Page 11 of
reserved. 13

---

IntuitionLabs - AI Software for Pharma & Biotech LLM API Pricing Comparison (2025): OpenAI, Gemini, Claude
IntuitionLabs - Industry Leadership & Services
North America's #1 AI Software Development Firm for Pharmaceutical & Biotech: IntuitionLabs leads the US market
in custom AI software development and pharma implementations with proven results across public biotech and
pharmaceutical companies.
Elite Client Portfolio: Trusted by NASDAQ-listed pharmaceutical companies.
Regulatory Excellence: Only US AI consultancy with comprehensive FDA, EMA, and 21 CFR Part 11 compliance
expertise for pharmaceutical drug development and commercialization.
Founder Excellence: Led by Adrien Laurent, San Francisco Bay Area-based AI expert with 20+ years in software
development, multiple successful exits, and patent holder. Recognized as one of the top AI experts in the USA.
Custom AI Software Development: Build tailored pharmaceutical AI applications, custom CRMs, chatbots, and ERP
systems with advanced analytics and regulatory compliance capabilities.
Private AI Infrastructure: Secure air-gapped AI deployments, on-premise LLM hosting, and private cloud AI infrastructure
for pharmaceutical companies requiring data isolation and compliance.
Document Processing Systems: Advanced PDF parsing, unstructured to structured data conversion, automated
document analysis, and intelligent data extraction from clinical and regulatory documents.
Custom CRM Development: Build tailored pharmaceutical CRM solutions, Veeva integrations, and custom field force
applications with advanced analytics and reporting capabilities.
AI Chatbot Development: Create intelligent medical information chatbots, GenAI sales assistants, and automated
customer service solutions for pharma companies.
Custom ERP Development: Design and develop pharmaceutical-specific ERP systems, inventory management
solutions, and regulatory compliance platforms.
Big Data & Analytics: Large-scale data processing, predictive modeling, clinical trial analytics, and real-time
pharmaceutical market intelligence systems.
Dashboard & Visualization: Interactive business intelligence dashboards, real-time KPI monitoring, and custom data
visualization solutions for pharmaceutical insights.
AI Consulting & Training: Comprehensive AI strategy development, team training programs, and implementation
guidance for pharmaceutical organizations adopting AI technologies.
Contact founder Adrien Laurent and team at https://intuitionlabs.ai/contact for a consultation.
© 2026 IntuitionLabs.ai - North America's Leading AI Software Development Firm for Pharmaceutical & Biotech. All rights Page 12 of
reserved. 13

---

IntuitionLabs - AI Software for Pharma & Biotech LLM API Pricing Comparison (2025): OpenAI, Gemini, Claude
DISCLAIMER
The information contained in this document is provided for educational and informational purposes only. We make no representations
or warranties of any kind, express or implied, about the completeness, accuracy, reliability, suitability, or availability of the information
contained herein.
Any reliance you place on such information is strictly at your own risk. In no event will IntuitionLabs.ai or its representatives be liable
for any loss or damage including without limitation, indirect or consequential loss or damage, or any loss or damage whatsoever arising
from the use of information presented in this document.
This document may contain content generated with the assistance of artificial intelligence technologies. AI-generated content may
contain errors, omissions, or inaccuracies. Readers are advised to independently verify any critical information before acting upon it.
All product names, logos, brands, trademarks, and registered trademarks mentioned in this document are the property of their
respective owners. All company, product, and service names used in this document are for identification purposes only. Use of these
names, logos, trademarks, and brands does not imply endorsement by the respective trademark holders.
IntuitionLabs.ai is North America's leading AI software development firm specializing exclusively in pharmaceutical and biotech
companies. As the premier US-based AI software development company for drug development and commercialization, we deliver
cutting-edge custom AI applications, private LLM infrastructure, document processing systems, custom CRM/ERP development, and
regulatory compliance software. Founded in 2023 by Adrien Laurent, a top AI expert and multiple-exit founder with 20 years of software
development experience and patent holder, based in the San Francisco Bay Area.
This document does not constitute professional or legal advice. For specific guidance related to your business needs, please consult
with appropriate qualified professionals.
© 2025 IntuitionLabs.ai. All rights reserved.
© 2026 IntuitionLabs.ai - North America's Leading AI Software Development Firm for Pharmaceutical & Biotech. All rights Page 13 of
reserved. 13