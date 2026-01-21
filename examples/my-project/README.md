# My Project

Example project using the AI system.

## Setup

This project was set up with:

```bash
# Copy AI system
cp -r ai-system/.ai ./
mkdir .ai-local
echo ".ai-local/" >> .gitignore

# Copy universal entry point
cp ai-system/AGENTS.md ./

# (Optional) Copy tool adapter
cp ai-system/adapters/claude/CLAUDE.md ./
```

## Usage

1. Start session: `/boot`
2. Do work
3. Save session: `/save`

## Files

- `AGENTS.md` - AI entry point
- `.ai/` - AI system definitions
- `.ai-local/` - Local session state (gitignored)
