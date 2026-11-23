# Setup

Run the project locally.

1. [STEP 1]
2. [STEP 2]

## AI agent skills

This project uses global skills. They are not copied into the repo.

- Plugins (Superpowers, Ponytail, Caveman, mattpocock-skills, ux-ui-agent-skills, unslop-ui): Claude Code offers to install them when you open the project. They are listed in `.claude/settings.json`.
- Install these skills by hand (needs Node.js). Pick Claude Code as the target when asked:
  ```bash
  npx skills add JuliusBrussee/caveman                    # caveman, caveman-commit, caveman-review and more
  npx skills add pbakaus/impeccable                       # impeccable
  npx skills add nextlevelbuilder/ui-ux-pro-max-skill     # ui-ux-pro-max
  npx skills add Leonxlnx/taste-skill                     # design-taste-frontend (pick it from the list)
  ```
- `unslop-ui` also needs the `pstack` plugin. Install it separately if you use `/unslop-ui`.

Check with `/skills` in Claude Code.
