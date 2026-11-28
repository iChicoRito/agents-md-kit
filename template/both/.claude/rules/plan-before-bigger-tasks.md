# Plan before bigger tasks

For any task bigger than a small fix:

1. Understand the goal and read the code it touches.
2. Write a short plan: what changes, which files, which skills or plugins are needed.
3. Check that the plan is not over-engineered.
4. Save the plan, then implement. Keep the code as simple as the plan.

## Save every plan

This applies to every agent and model, and to plan mode, where the plan may otherwise sit only in a temp or tool-private place.

- When a plan is finished, copy it word for word to `<YYYY-MM-DD>-<short-topic>.md` in `.claude/plan/` (Claude Code) or `.agents/plan/` (any other agent). Create the folder if it does not exist. Do not shorten, reword or reformat it.
- Save it before the first code change. Implement from that file.
- A plan that changes later: save the new version as a new file. Do not edit the old one.
