# Open Questions

Nothing here blocks your review. The first four block the start of Step 11.

## Blocking

**1. Tier B licensing. Who sends the emails, and when.**
Two emails: Realtor.com research, and `econdata@redfin.com`. Both asking for written confirmation that automated retrieval and storage of the published research files in a private analytics database is permitted. The entire exit-liquidity pillar of the Opportunity Score, and the Exit Liquidity Deterioration pattern, depend on the answers. Twenty minutes of work, potentially weeks of waiting, so this should happen before M00 rather than at M07.

If the answers are no, the score drops to six pillars and PatternIQ can rank markets on acquisition and economic conditions but not on whether you could sell. That is a materially different product and you should decide now whether it is still worth building.

**2. Palette.**
The wireframes use your existing primary palette: navy, brushed gold, terra cotta, off-white. That was a choice, not an instruction from you. PatternIQ is a new venture with no palette of its own, and the primary palette reads as credible and financial, which is what Section 25 asks for. It is also visually tied to your teaching materials. Confirm, or give me a different direction and the wireframes change in one CSS block.

**3. Where this runs.**
Architecture assumes Docker Compose on a single VPS, roughly $20 to $40 per month. Alternatives are a local machine (free, but no scheduled Monday morning refresh unless it stays awake) or a managed platform like Railway or Fly (simpler, roughly $30 to $60 per month). This affects M00 and nothing else, but M00 is first.

**4. The RentCast question, asked now rather than later.**
Free data supports market analysis. It does not support address-level underwriting, because there is no free source of comps or an AVM. RentCast at $74 per month closes that gap and has the most permissive published license of any provider researched. Buying it changes the schema (a property records layer), the Deal Analyzer (real comps instead of your ARV estimate), and roughly two milestones of work.

Answering "not yet" is a perfectly good answer. It is worth answering deliberately rather than by default, because the Deal Analyzer design differs depending on it.

## Not blocking, but worth deciding early

**5. Geography scope for Phase 1.**
National county and CBSA coverage is roughly 4,000 markets and pushes against the BLS 500-queries-per-day limit, which shapes the ingestion schedule. Starting with a handful of states would make M03 through M08 noticeably faster and the coverage report more legible. National is the right long-term answer. Starting narrower is the faster path to something useful.

**6. Horizon.**
Step 8 uses a 12-month primary horizon for outcome labels, with 6 and 18 as robustness checks. If your actual flip cycle is shorter, 6 months should be primary instead. Your two completed projects ran 176 and 151 days, which points toward 6 months being closer to your reality. Confirm and the label definition changes.

**7. FFR label weights.**
The 50/30/20 split across appreciation, days on market, and sale-to-list is my judgment about what drives a flip outcome. You have actually done this. If the split is wrong, say so now, because every validation result depends on it.

**8. Contingency default.**
The Deal Analyzer wireframe shows 12 percent. Your two completed projects ran 13.5 and 12.6 percent over budget. Two projects establish nothing statistically, but the default should probably not sit below your own observed overrun rate.

**9. What happens to the twelve unimplemented patterns.**
Step 7 implements three and documents twelve as library entries marked not implemented. The alternative is implementing more thinly. I think three done properly is the better product, but it is your call.

**10. Naming.**
The master spec calls it a Flip Opportunity Score. Given how hard this design works to prevent the score being read as a recommendation, a name like Market Conditions Index would carry less implication. Opportunity Score is more direct. Worth a moment's thought before it is in the schema, the UI, and your habits.
