Draft a hackathon demo brief for vista-colloseum, a repository intended to use a subset of VistaMobileBE and Flutter-mobile-app. The goal is a Social Market demonstration; the feature is still in PRD/concept design.

Use the linked remote TPX branch as the current design source: [https://github.com/VistaMarkets/Flutter-mobile-app/tree/docs/legal-posture/tpx](https://github.com/VistaMarkets/Flutter-mobile-app/tree/docs/legal-posture/tpx). The client walkthrough covers the rest of the app, but its demo section does not exist yet. Follow the current TPX branch's no-token, manual-replication model. Its economics give the listed trader 40% of fees on trades in that trader's TPX market; they do not define a payment for manual replication of a separate asset order. Treat that direct-copy payout as a proposed demo requirement until the design defines its source, trigger, and amount. Recheck the branch head before implementation.

Plan a video showing two phones.
Phone A creates an order and makes it copyable.
Phone B chooses to copy Phone A's trade and manually places their own order only after choosing to copy.
After the copied trade completes successfully, Phone A receives a direct payment because Phone B copied their trade. Show a payment credit, not an increase in token value.
Reuse existing Flutter-mobile-app and VistaMobileBE features where they fit.
Mocks and fakes are acceptable where needed for the hackathon video.
The Social Market feature will be designed and added to this repo later; do not present it as built.
Show the scene sequence across both phones and identify which visible steps can use existing functionality, which require new design, and which can be mocked. Verify reuse claims against current app and backend code. Identify the direct-copy payment as proposed until its rule is documented.
Return a proposed demo section for the client walkthrough plus the unresolved payment design details. Do not present the separate TPX market fee share as proof of a per-copy payment.
Check that Phone B actively chooses and places their own trade, that no token is issued or shown appreciating, and that Phone A visibly receives a direct payment after the copy completes. Label mocks and proposed behavior.
