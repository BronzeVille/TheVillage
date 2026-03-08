# CLAUDE.md — AI Assistant Guide for TheVillage

## Project Overview

**TheVillage** is a peaceful, cozy village simulation project. The repository is currently in its earliest stage — initialized with a GPL v3 license and a minimal README. No source code exists yet.

- **License:** GNU General Public License v3
- **Repository:** BronzeVille/TheVillage
- **Description:** A peaceful, cozy village

---

## Current Repository State

```
TheVillage/
├── CLAUDE.md       ← This file
├── LICENSE         ← GNU GPL v3
└── README.md       ← Project title and one-line description
```

There is no source code, build system, test framework, or CI/CD configuration yet. This file will be updated as the project grows.

---

## Git Workflow

### Branching

- The default branch is `master`
- Feature branches should follow the pattern: `<feature-name>` or `<author>/<feature-name>`
- Claude-generated branches follow: `claude/<task-description>-<session-id>`

### Commit Style

- Use clear, imperative commit messages: `Add player movement`, `Fix collision detection`, `Update README`
- Keep commits focused and atomic
- Reference issue numbers where applicable: `Fix #12: resolve village NPC pathfinding`

### Push

Always push with tracking:
```bash
git push -u origin <branch-name>
```

---

## Development Conventions (to be established)

Since this project has no code yet, conventions should be decided and documented here as development begins. Suggested areas to define:

- **Language / Framework:** What technology stack will be used? (e.g., JavaScript/TypeScript, Python, Unity, Godot)
- **Folder structure:** Where do source files, assets, and tests live?
- **Code style:** Linting rules, formatting tools (Prettier, ESLint, Black, etc.)
- **Testing:** What test framework and coverage expectations apply?
- **Build system:** How is the project built and run locally?

---

## For AI Assistants

### When working in this repository

1. **Read this file first** to understand the current state before making changes.
2. **Update this file** when you add new technologies, establish conventions, or change the structure.
3. **Check for a README** before creating documentation — keep README user-facing and CLAUDE.md AI/developer-facing.
4. **Do not assume a tech stack** — the project has none yet. Ask or infer from context before introducing dependencies.
5. **Follow GPL v3 requirements** — all contributions must be compatible with the GNU General Public License v3.

### Branch requirements

- Develop on the branch specified in the task context
- Never push to `master` directly without explicit permission
- Use `git push -u origin <branch-name>` for all pushes

### File hygiene

- Prefer editing existing files over creating new ones
- Do not create unnecessary boilerplate or placeholder files
- Keep the repository clean; avoid committing build artifacts, logs, or `.env` files

---

## License

This project is licensed under the **GNU General Public License v3**. See [LICENSE](./LICENSE) for full terms.

Any code added to this repository must be GPL v3 compatible.
