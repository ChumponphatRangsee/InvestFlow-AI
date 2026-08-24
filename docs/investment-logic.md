# Investment Logic

## 1. Purpose

This document defines the investment decision logic for Research Ledger. It
separates business quality, research judgment, market opportunity, portfolio
context, and final human decisions so future implementation does not collapse
them into one opaque score.

The document describes methodology and guardrails only. It must not contain
live fair values, current market recommendations, or real-time buy/sell calls.

## 2. Investment Workflow

The intended workflow is:

```text
Discover
  -> Quantitative Screen
  -> AI Research
  -> Human Review
  -> Paper Portfolio
  -> Thesis Tracking
  -> Re-evaluation
```

Quantitative screening narrows the universe. Research explains the business,
risks, valuation, and evidence. Portfolio context checks whether a possible
action fits the user's current holdings, allocation, cash, and risk limits.
Only after human review can any paper-portfolio action or confirmed ledger
change occur.

Research Ledger is not a live trading bot, broker, or order execution system.

## 3. Score Types and Separation

Scores must remain separate because they answer different questions.

| Score | Question answered | Must not do |
| --- | --- | --- |
| Quantitative score | Does the company pass deterministic quality and financial filters for its business model? | Must not imply the stock is a buy. |
| Research score | How strong is the qualitative and evidence-backed investment case? | Must not hide missing sources or fabricated claims. |
| Opportunity score | Is the current price attractive versus explicit fair value, upside, and margin of safety? | Must not ignore valuation because the business is high quality. |
| Portfolio-context score | Does the idea fit the current portfolio, allocation, risk, and position-sizing constraints? | Must not rewrite the underlying quality or research evidence. |
| Final decision | What should the human reviewer do now? | Must not be generated as an automatic portfolio action. |

Quantitative quality and opportunity are separate. An excellent company with
insufficient expected upside is a Watch or Wait candidate, not an automatic
Buy.

## 4. Candidate / Buy / Watch / Hold / Reduce / Reject Definitions

| Decision label | Definition |
| --- | --- |
| Candidate | Worth deeper review because initial quantitative or research evidence is promising. |
| Buy | Human reviewer accepts that business quality, evidence, valuation, margin of safety, and portfolio fit justify a new or increased paper position. |
| Watch | Good or potentially good idea, but price, evidence, timing, risk, or portfolio fit is not strong enough for action. |
| Hold | Existing position remains acceptable under the current thesis, valuation, and risk context. |
| Reduce | Existing exposure is too large, thesis quality has weakened, valuation is no longer attractive, or risk limits are breached. |
| Reject | Evidence, quality, valuation, risk, or data completeness is insufficient for continued consideration. |

These labels are decision states, not brokerage instructions.

## 5. Fair Value and Margin-of-Safety Principles

Fair value must be explicit. Expected upside must be explicit. Margin of safety
must be explicit.

Valuation work should state:

- valuation method;
- input assumptions;
- source and freshness of facts;
- bull, base, and bear case if supported;
- estimated fair value or fair-value range;
- current price used for comparison;
- expected upside or downside; and
- margin of safety threshold.

Valuation can override business quality. A high-quality company can be a poor
opportunity when the price already reflects optimistic assumptions.

## 6. Opportunity Score Logic

Opportunity score should combine the valuation setup with timing and risk. It
should consider:

- expected upside versus fair value;
- margin of safety;
- confidence in valuation inputs;
- downside risk and thesis fragility;
- catalyst or re-evaluation timing;
- liquidity or practical constraints when relevant; and
- portfolio fit.

Opportunity score must not be calculated from quality score alone. It should be
low or incomplete when fair value, current price, upside, or margin of safety is
missing.

Conceptual example:

```text
Excellent company + insufficient upside = Watch / Wait, not automatic Buy.
```

## 7. Portfolio Context and Rebalance Considerations

Portfolio context may influence opportunity score and sizing rationale, but it
must not rewrite quantitative evidence or research facts.

Portfolio-aware decisions should consider:

- current position size;
- account and asset exposure;
- sector, theme, and concentration risk;
- cash or deployable capital;
- target allocation and DCA plan when implemented;
- realized and unrealized P&L context;
- correlation with existing holdings when supported; and
- whether a new action would breach risk limits.

The system may propose a watch, draft, or review item, but confirmed portfolio
facts still require the human transaction workflow.

## 8. Human Review Requirement

Human review is required before any portfolio action. AI, screenshot import,
spreadsheet import, or research code may create drafts or recommendations only.
They must not confirm transactions, mutate confirmed ledger rows, or place live
trades.

The human reviewer is responsible for accepting, rejecting, or modifying the
decision based on the surfaced evidence and assumptions.

## 9. Rules AI Must Not Violate

- Do not fabricate facts, sources, assumptions, prices, fair values, or
  valuation inputs.
- Do not convert missing data to zero.
- Do not treat a high quantitative score as a buy recommendation.
- Do not merge quantitative score, research score, opportunity score, and
  portfolio-context score into one unexplained value.
- Do not perform deterministic arithmetic in the LLM when code can calculate
  it.
- Do not use provider-specific raw fields as domain logic.
- Do not bypass the analysis inbox or transaction draft review workflow.
- Do not mutate confirmed transactions.
- Do not describe paper-portfolio actions as live trading.

## 10. Future Implementation Notes

Future implementation should persist separate score components, evidence,
valuation assumptions, market-data freshness, portfolio-context snapshots, and
human decisions. Deterministic calculations should live in typed backend code
with tests. LLM output should be structured, source-backed, and treated as
advisory until reviewed.

PR5 should focus on prices, FX, valuation snapshots, and performance plumbing.
It should not prematurely implement the full research-to-decision bridge.
