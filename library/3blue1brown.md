# 3Blue1Brown — Deep Learning Series

## Metadata
- **Creator:** Grant Sanderson
- **Type:** YouTube Video Series
- **Published:** 2017–2024 (ongoing)
- **URL:** https://www.youtube.com/playlist?list=PLLMP7TazTxHrgVk7w1EKpLBIDoC50QrPS
- **Tags:** ai, neural-networks, deep-learning, transformers, llm, attention, visualization, education
- **Added:** 2026-04-17
- **Projects:** docs/ai-engineering (foundational AI concepts for essay audience)

## Why This Matters (personal)
The author has watched all videos in this series and considers them excellent resources for understanding the AI domain. The visual, intuition-first approach makes concepts like attention, transformers, and token embeddings accessible to engineers who work *with* AI but aren't ML researchers — exactly the audience for the `docs/ai-engineering/` essays. When The Shift uses terms like "token" or "transformer," these videos are the reference point for what a clear explanation looks like.

## The Series

### Deep Learning Chapters (core series)

| # | Title | YouTube | Duration | Published |
|---|---|---|---|---|
| 1 | But what is a neural network? | [watch](https://www.youtube.com/watch?v=aircAruvnKk) | ~19 min | Oct 2017 |
| 2 | Gradient descent, how neural networks learn | [watch](https://www.youtube.com/watch?v=IHZwWFHWa-w) | ~21 min | Oct 2017 |
| 3 | Backpropagation, intuitively | [watch](https://www.youtube.com/watch?v=Ilg3gGewQ5U) | ~14 min | Nov 2017 |
| 4 | Backpropagation calculus | [watch](https://www.youtube.com/watch?v=tIeHLnjs5U8) | ~10 min | Nov 2017 |
| 5 | Transformers, the tech behind LLMs | [watch](https://www.youtube.com/watch?v=wjZofJX0v4M) | ~27 min | Apr 2024 |
| 6 | Attention in transformers, step-by-step | [watch](https://www.youtube.com/watch?v=eMlx5fFNoYc) | ~26 min | Apr 2024 |
| 7 | How might LLMs store facts | [watch](https://www.youtube.com/watch?v=9-Jl0dxWQs8) | ~23 min | Aug 2024 |

### Standalone

| Title | YouTube | Duration | Published |
|---|---|---|---|
| Large Language Models explained briefly | [watch](https://www.youtube.com/watch?v=LPZh9BOjkQs) | ~8 min | Nov 2024 |

## Key Themes

- **Visual intuition over formalism** — Complex concepts (gradient descent, backpropagation, attention matrices) are explained through animation and spatial reasoning before any math appears. This is Grant Sanderson's signature: build the intuition first, then the formalism has somewhere to land.
- **Tokenization and embeddings** — Chapter 5 explains tokenization (breaking text into chunks), word embeddings (associating tokens with high-dimensional vectors that encode meaning), and how these flow through the transformer. Directly relevant to explaining "what is a token" for a non-ML audience.
- **Attention as context propagation** — Chapter 6 shows how attention allows vectors to "talk to each other" and update based on surrounding context. The "mole" example (animal vs. chemistry vs. skin) demonstrates why context matters.
- **Facts stored in MLPs** — Chapter 7 explores where factual knowledge lives in a transformer, using mechanistic interpretability research from Google DeepMind. Relevant to understanding AI confidence and hallucination.
- **The brief overview** — The standalone "LLMs explained briefly" video is an 8-minute entry point, created for a Computer History Museum exhibit. Good for the audience who wants the gist without committing to the full series.

## Relevance to Active Work

- **The Shift** — The essay says "A large language model is a statistical model trained on text. It predicts the most likely next sequence of tokens given the preceding context." A peer asked "what exactly is a token?" Chapter 5's tokenization explanation is the reference for making this accessible.
- **Sycophancy and confidence** — Chapter 7's exploration of how LLMs store facts connects to why AI is confident about wrong answers: the storage mechanism doesn't have a built-in uncertainty signal.
- **Audience calibration** — The essays target engineers, not ML researchers. 3Blue1Brown targets the same audience with the same philosophy: explain the real thing clearly, don't dumb it down or dress it up.

## Transcripts

Fetched transcripts are stored in `research/3blue1brown/`:
- See individual transcript files for timestamped text

*This entry was created with AI assistance (Cursor) and has not been fully reviewed by the author. The "Why This Matters" section contains biographical content that needs `voice-approved` validation. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
