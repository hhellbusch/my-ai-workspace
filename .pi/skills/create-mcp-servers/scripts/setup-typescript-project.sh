#!/bin/bash
# Setup TypeScript MCP Server Project
# Usage: bash setup-typescript-project.sh <server-name>

set -e

SERVER_NAME="${1:?Usage: setup-typescript-project.sh <server-name>}"
PROJECT_DIR="$HOME/Developer/mcp/$SERVER_NAME"

echo "Creating TypeScript MCP server: $SERVER_NAME"
echo "Location: $PROJECT_DIR"

# Create directory structure
mkdir -p "$PROJECT_DIR/src"
cd "$PROJECT_DIR"

# Initialize npm project
npm init -y

# Install dependencies
npm install @modelcontextprotocol/sdk
npm install -D typescript @types/node

# Create tsconfig.json
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "esModuleInterop": true,
    "strict": true,
    "outDir": "./build",
    "rootDir": "./src",
    "declaration": true,
    "skipLibCheck": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules"]
}
EOF

# Update package.json for ES modules
node -e "
const pkg = require('./package.json');
pkg.type = 'module';
pkg.main = 'build/index.js';
pkg.scripts = {
  build: 'tsc',
  start: 'node build/index.js',
  dev: 'tsc && node build/index.js'
};
require('fs').writeFileSync('package.json', JSON.stringify(pkg, null, 2));
"

# Create .gitignore
cat > .gitignore << 'EOF'
node_modules/
build/
.env
*.log
EOF

# Create README
cat > README.md << EOF
# $SERVER_NAME

MCP server for Claude.

## Setup

\`\`\`bash
cd $PROJECT_DIR
npm install
npm run build
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
  -- $(which node) $PROJECT_DIR/build/index.js
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
echo "1. Copy template to src/index.ts"
echo "2. Run: npm run build"
echo "3. Set environment variables"
echo "4. Install in Claude Code"
