# VistaColloseum context

## Project vocabulary

| Term | Expansion | Meaning here |
| --- | --- | --- |
| VC | VistaColloseum | This demo project; GitHub repository `VistaMarkets/VistaColosseum` |
| VMBE | VistaMobileBE | Backend reference repository |
| FMA | Flutter-mobile-app | Frontend reference repository |
| TPX | Trader Performance Exchange | The trader-performance market concept documented in FMA's `tpx/` directory |
| API | Application Programming Interface | A defined interface between components or services |
| UI | User Interface | Screens, controls, and visible feedback |
| UX | User Experience | How a person understands and uses the product |
| PnL | Profit and Loss | A position's or trader's gain or loss; simulated where shown in the demo |
| DEX | Decentralized Exchange | A general exchange category; preserve VMBE's more specific domain term `Venue` when referring to its model |
| RPC | Remote Procedure Call | A request to a remote service, including a blockchain node |
| ADR | Architecture Decision Record | A documented design decision and its reasoning |

VC is the agreed project name. Its GitHub repository spelling is
`VistaMarkets/VistaColosseum`; use that exact slug for GitHub operations.

## References

- VMBE: `/home/alex/VistaMobileBE`; read `CONTEXT.md` for backend terminology.
- FMA: `/home/alex/Flutter-mobile-app`; read `docs/APP_FLOW.md` for user flows
  and `tpx/README.md` for TPX's definition and design status.

Read the references and write original, lightweight implementations of the
core demo behavior. Do not copy their source files or transplant their
implementations. Reusing the existing Vista logo assets is explicitly
authorized for the READMEs.

Terms describe shared vocabulary; they do not establish that a feature is
implemented or approved for this demo. Financial actions remain simulated,
and existing safety gates remain required.
