# Setup

Run the project locally.

1. [STEP 1]
2. [STEP 2]

## AI agent skills

This project uses global skills. They are not copied into the repo.

- Plugins (Superpowers, Ponytail, Caveman): Claude Code offers to install them when you open the project. They are listed in `.claude/settings.json`.
- Install the design skills by hand (needs Node.js). Pick Claude Code as the target when asked:
  ```bash
  npx skills add pbakaus/impeccable                       # impeccable
  npx skills add nextlevelbuilder/ui-ux-pro-max-skill     # ui-ux-pro-max
  npx skills add Leonxlnx/taste-skill                     # design-taste-frontend (pick it from the list)
  ```
- Optional: `unslop-ui` plugin (`felipebasurto/unslop-ui`), needs `pstack`.

Check with `/skills` in Claude Code.
