#!/bin/bash
# Setup Python MCP Server Project
# Usage: bash setup-python-project.sh <server-name>

set -e

SERVER_NAME="${1:?Usage: setup-python-project.sh <server-name>}"
PROJECT_DIR="$HOME/Developer/mcp/$SERVER_NAME"

echo "Creating Python MCP server: $SERVER_NAME"
echo "Location: $PROJECT_DIR"

# Create directory structure
mkdir -p "$PROJECT_DIR/src"
cd "$PROJECT_DIR"

# Initialize with uv
uv init --name "$SERVER_NAME"

# Add MCP SDK dependency
uv add mcp

# Create __init__.py for src package
touch src/__init__.py

# Create .gitignore
cat > .gitignore << 'EOF'
__pycache__/
*.py[cod]
*$py.class
.venv/
.env
*.egg-info/
dist/
build/
.uv/
EOF

# Create README
cat > README.md << EOF
# $SERVER_NAME

MCP server for Claude.

## Setup

\`\`\`bash
cd $PROJECT_DIR
uv sync
\`\`\`

## Environment Variables

Set required environment variables in ~/.zshrc:

\`\`\`bash
export API_KEY="your-key-here"
\`\`\`

## Install in Claude Code

\`\`\`bash
claude mcp add --transport stdio $SERVER_NAME \\
  --env API_KEY='\${API_KEY}' \\
  -- $(which uv) --directory $PROJECT_DIR run python -m src.server
\`\`\`

## Logs

\`\`\`bash
tail -f ~/Library/Logs/Claude/mcp-server-$SERVER_NAME.log
\`\`\`
EOF

echo ""
echo "✓ Project created at $PROJECT_DIR"
echo ""
echo "Next steps:"
echo "1. Copy template to src/server.py"
echo "2. Set environment variables"
echo "3. Install in Claude Code"
