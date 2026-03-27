# Commit

Create a git commit following Lapin Browser's conventions.

## Steps

1. Run `git status` to see all modified and untracked files
2. Run `git diff` (staged and unstaged) to understand what changed
3. Run `git log --oneline -10` to match the project's commit style
4. Stage the relevant files by name — never use `git add -A` or `git add .`
5. Write the commit message and commit

## Commit message rules

- Imperative mood, sentence-case subject: `Add`, `Fix`, `Update`, `Bump`, `Remove`
- No trailing period on the subject line
- Keep the subject under 72 characters
- Add a body only when the *why* needs explanation — not to restate the diff
- **Never** include `Co-Authored-By`, `Generated with`, or any AI attribution
- Pass the message via heredoc to preserve formatting:

```bash
git commit -m "$(cat <<'EOF'
Subject line here

Optional body explaining why, not what.
EOF
)"
```

## After committing

Run `git status` to confirm the working tree is clean.
