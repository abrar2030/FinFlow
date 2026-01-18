# Contributing to FinFlow

Thank you for your interest in contributing to FinFlow! This document provides guidelines and instructions for contributing.

---

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Code Style](#code-style)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Commit Guidelines](#commit-guidelines)
- [Documentation](#documentation)

---

## Getting Started

### Prerequisites

Before contributing, ensure you have:

- Node.js 16+ installed
- Python 3.9+ installed
- Docker and Docker Compose
- Git configured with your GitHub account

### Fork and Clone

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/FinFlow.git
cd FinFlow

# Add upstream remote
git remote add upstream https://github.com/quantsingularity/FinFlow.git

# Verify remotes
git remote -v
```

---

## Development Setup

### 1. Install Dependencies

```bash
# Run the setup script
./scripts/finflow-setup.sh --environment development

# Or manually:
# Backend services
cd backend/auth-service && npm install
cd ../payments-service && npm install
# ... repeat for other services

# Python services
cd backend/credit-engine
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 2. Configure Environment

```bash
# Copy example environment files
cp backend/auth-service/.env.example backend/auth-service/.env
# Edit .env files with your local configuration
```

### 3. Start Development Environment

```bash
# Using dev script
./scripts/finflow-dev.sh --action start

# Or using Docker Compose
docker-compose up
```

---

## Code Style

### TypeScript/JavaScript

We follow the Airbnb JavaScript Style Guide with some modifications.

**Key Rules:**

- Use TypeScript for all new code
- Use 2 spaces for indentation
- Use single quotes for strings
- Use semicolons
- Max line length: 100 characters
- Use const/let, never var

**Example:**

```typescript
// Good
const calculateTotal = (items: Item[]): number => {
  return items.reduce((sum, item) => sum + item.price, 0);
};

// Bad
var calculateTotal = function (items) {
  return items.reduce(function (sum, item) {
    return sum + item.price;
  }, 0);
};
```

**Run Linter:**

```bash
# Check code style
npm run lint

# Auto-fix issues
npm run lint:fix

# Or use quality script
./scripts/finflow-quality.sh --mode fix
```

### Python

We follow PEP 8 style guide.

**Key Rules:**

- Use 4 spaces for indentation
- Max line length: 88 characters (Black formatter)
- Use type hints for function signatures
- Use docstrings for functions and classes

**Example:**

```python
# Good
def calculate_credit_score(
    income: float,
    num_invoices: int,
    avg_cashflow: float
) -> float:
    """
    Calculate credit score based on financial data.

    Args:
        income: Annual income
        num_invoices: Number of processed invoices
        avg_cashflow: Average monthly cash flow

    Returns:
        Credit score between 0.0 and 1.0
    """
    base_score = (income / 100000) * 0.3 + (num_invoices / 100) * 0.3
    return min(0.9, base_score)
```

**Run Linter:**

```bash
# Format with Black
black backend/credit-engine/src/

# Check with Flake8
flake8 backend/credit-engine/src/

# Type checking with mypy
mypy backend/credit-engine/src/
```

---

## Testing

All new features and bug fixes must include tests.

### Running Tests

```bash
# Run all tests
./scripts/finflow-test-runner.sh --type all

# Run unit tests only
./scripts/finflow-test-runner.sh --type unit

# Run tests for specific service
cd backend/auth-service
npm test

# Run with coverage
npm test -- --coverage
```

### Writing Tests

**TypeScript (Jest):**

```typescript
// auth.service.test.ts
describe("AuthService", () => {
  describe("login", () => {
    it("should return user and token on successful login", async () => {
      // Arrange
      const email = "test@example.com";
      const password = "password123";

      // Act
      const result = await authService.login(email, password);

      // Assert
      expect(result).toHaveProperty("token");
      expect(result).toHaveProperty("user");
      expect(result.user.email).toBe(email);
    });
  });
});
```

**Python (Pytest):**

```python
# test_credit_engine.py
def test_calculate_credit_score():
    """Test credit score calculation with valid inputs"""
    # Arrange
    income = 75000
    num_invoices = 45
    avg_cashflow = 5000

    # Act
    score = calculate_credit_score(income, num_invoices, avg_cashflow)

    # Assert
    assert 0.0 <= score <= 1.0
    assert score > 0.6  # High-income should yield good score
```

### Test Coverage Requirements

- Minimum 80% code coverage for new code
- 100% coverage for critical paths (auth, payments, accounting)
- Integration tests for API endpoints
- E2E tests for critical user workflows

---

## Pull Request Process

### 1. Create a Feature Branch

```bash
# Update your fork
git fetch upstream
git checkout main
git merge upstream/main

# Create feature branch
git checkout -b feature/your-feature-name
# or
git checkout -b fix/bug-description
```

### 2. Make Changes

- Write code following style guidelines
- Add tests for new functionality
- Update documentation as needed
- Ensure all tests pass

### 3. Commit Changes

Follow our commit message conventions (see below).

```bash
git add .
git commit -m "feat: add payment refund feature"
```

### 4. Push and Create PR

```bash
# Push to your fork
git push origin feature/your-feature-name

# Go to GitHub and create Pull Request
# Fill in the PR template with details
```

### 5. Code Review

- Address reviewer feedback
- Make requested changes
- Push updates to the same branch
- Request re-review when ready

### 6. Merge

Once approved, a maintainer will merge your PR.

---

## Commit Guidelines

We follow Conventional Commits specification.

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

| Type         | Description                  | Example                                           |
| ------------ | ---------------------------- | ------------------------------------------------- |
| **feat**     | New feature                  | `feat(payments): add Square integration`          |
| **fix**      | Bug fix                      | `fix(auth): resolve JWT expiration issue`         |
| **docs**     | Documentation                | `docs(api): update payment endpoints`             |
| **style**    | Code style (no logic change) | `style(accounting): format code with Prettier`    |
| **refactor** | Code refactoring             | `refactor(analytics): optimize dashboard queries` |
| **perf**     | Performance improvement      | `perf(db): add index on user_id column`           |
| **test**     | Adding/updating tests        | `test(auth): add login integration tests`         |
| **chore**    | Maintenance tasks            | `chore(deps): update dependencies`                |
| **ci**       | CI/CD changes                | `ci(github): add deployment workflow`             |

### Examples

**Good commit messages:**

```
feat(credit-engine): implement ML-based default prediction

Add XGBoost model for predicting loan defaults based on
historical data. Includes model training script and API endpoint.

Closes #123
```

```
fix(payments): handle Stripe webhook signature validation

Stripe webhooks were failing due to incorrect signature
verification. Updated to use raw request body.

Fixes #456
```

**Bad commit messages:**

```
fixed bug
Update code
WIP
```

---

## Documentation

### Updating Documentation

When making changes, update relevant documentation:

1. **API Changes**: Update `docs/API.md`
2. **Configuration**: Update `docs/CONFIGURATION.md`
3. **New Features**: Update `docs/FEATURE_MATRIX.md`
4. **Architecture**: Update `docs/ARCHITECTURE.md` if applicable

### Documentation Standards

- Use clear, concise language
- Include code examples
- Keep formatting consistent
- Update table of contents
- Add cross-references to related docs

### Generating Documentation

```bash
# Generate API documentation
./scripts/finflow-docs.sh --action generate

# Update README
./scripts/finflow-docs.sh --update-readme
```

---

## Issue Guidelines

### Reporting Bugs

Use the bug report template and include:

- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Environment details (OS, versions)
- Error messages and logs
- Screenshots if applicable

### Requesting Features

Use the feature request template and include:

- Clear description of the feature
- Use case and motivation
- Proposed implementation (if any)
- Alternatives considered

---

## Code Review Guidelines

### For Reviewers

- Be constructive and respectful
- Provide specific, actionable feedback
- Approve when code meets standards
- Request changes when improvements needed
- Comment on implementation approaches

### For Contributors

- Respond to all feedback
- Ask for clarification if needed
- Make requested changes promptly
- Mark conversations as resolved
- Thank reviewers for their time

---

## Community Guidelines

- Be respectful and inclusive
- Welcome newcomers
- Help others learn
- Share knowledge
- Report inappropriate behavior

---

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---
