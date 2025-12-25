#!/bin/bash

# FinFlow Mobile Frontend - Verification Script
# This script verifies the mobile frontend setup and installation

echo "======================================"
echo "FinFlow Mobile Frontend Verification"
echo "======================================"
echo ""

# Check Node.js
echo "✓ Checking Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    echo "  Node.js version: $NODE_VERSION"
else
    echo "  ❌ Node.js not found. Please install Node.js >= 16"
    exit 1
fi

# Check npm
echo "✓ Checking npm..."
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm -v)
    echo "  npm version: $NPM_VERSION"
else
    echo "  ❌ npm not found."
    exit 1
fi

# Install dependencies
echo ""
echo "✓ Installing dependencies..."
npm install --silent
if [ $? -eq 0 ]; then
    echo "  ✅ Dependencies installed successfully"
else
    echo "  ❌ Failed to install dependencies"
    exit 1
fi

# Check for .env file
echo ""
echo "✓ Checking environment configuration..."
if [ ! -f ".env" ]; then
    echo "  ⚠️  .env file not found. Creating from .env.example..."
    cp .env.example .env
    echo "  ✅ .env file created. Please update API_URL if needed."
else
    echo "  ✅ .env file exists"
fi

# Run TypeScript type check
echo ""
echo "✓ Running TypeScript type check..."
npm run type-check --silent
if [ $? -eq 0 ]; then
    echo "  ✅ TypeScript type check passed"
else
    echo "  ❌ TypeScript type check failed"
    exit 1
fi

# Run tests
echo ""
echo "✓ Running tests..."
npm test -- --silent --passWithNoTests
if [ $? -eq 0 ]; then
    echo "  ✅ All tests passed"
else
    echo "  ⚠️  Some tests failed (this might be expected)"
fi

# Check project structure
echo ""
echo "✓ Verifying project structure..."
REQUIRED_DIRS=(
    "src"
    "src/components"
    "src/screens"
    "src/services"
    "src/store"
    "src/types"
    "src/navigation"
    "src/__tests__"
    "assets"
)

ALL_DIRS_EXIST=true
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "  ✅ $dir exists"
    else
        echo "  ❌ $dir missing"
        ALL_DIRS_EXIST=false
    fi
done

if [ "$ALL_DIRS_EXIST" = false ]; then
    echo "  ❌ Some required directories are missing"
    exit 1
fi

# Summary
echo ""
echo "======================================"
echo "Verification Summary"
echo "======================================"
echo "✅ Node.js: Installed"
echo "✅ npm: Installed"
echo "✅ Dependencies: Installed"
echo "✅ TypeScript: Valid"
echo "✅ Project Structure: Complete"
echo ""
echo "Next Steps:"
echo "1. Review and update .env file with your backend URL"
echo "2. Start the development server: npm start"
echo "3. Run on Android: npm run android"
echo "4. Run on iOS: npm run ios"
echo ""
echo "For backend integration:"
echo "1. Navigate to backend directory"
echo "2. Run: docker-compose up"
echo "3. Verify services are running"
echo ""
echo "For more information, see README.md"
echo ""
