# Issue tracker: GitHub

VC issues and specs live in `VistaMarkets/VistaColosseum` on GitHub.
Use the native WSL `gh` CLI with inherited token overrides unset:
`env -u GH_TOKEN -u GITHUB_PERSONAL_ACCESS_TOKEN gh`.
Never read or source credential files. Use the existing authenticated session.

## Conventions

- Read: `gh issue view <number> --repo VistaMarkets/VistaColosseum --comments`.
- List: `gh issue list --repo VistaMarkets/VistaColosseum --state open`.
- Create: `gh issue create --repo VistaMarkets/VistaColosseum --title "..." --body-file <file>`.
- Comment: `gh issue comment <number> --repo VistaMarkets/VistaColosseum --body-file <file>`.
- Label: `gh issue edit <number> --repo VistaMarkets/VistaColosseum --add-label "..."`.
- Remove a label: use the same edit command with `--remove-label "..."`.
- Close: `gh issue close <number> --repo VistaMarkets/VistaColosseum`.

Apply the environment prefix above to these commands. Preserve actual newlines
in body files, and follow existing authorization and repository safety rules.

## Pull requests as a triage surface

**PRs as a request surface: no.**

## Skill vocabulary

"Publish to the issue tracker" means create a GitHub issue when authorized.
"Fetch the relevant ticket" means read the GitHub issue and its comments.
Use `docs/agents/triage-labels.md` for label strings.
