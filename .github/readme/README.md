# GitHub Workflows Documentation for FinFlow

This document provides a comprehensive overview of the GitHub Actions workflows used in the FinFlow project. These workflows automate the continuous integration and continuous deployment (CI/CD) processes, dependency management, and security scanning for the various components of the application.

## Overview

The FinFlow project is a financial flow management system with a microservices architecture. It uses GitHub Actions to automate testing, building, and deployment processes across multiple components:

- Backend Services:
  - Authentication Service
  - Payments Service
  - Accounting Service
  - Analytics Service
  - Credit Engine
- Frontend Application

The workflow architecture is designed to ensure code quality, security, and reliable deployments to both staging and production environments.

## Workflow Structure

### CI/CD Pipeline (`ci-cd.yml`)

This is the primary workflow that handles the continuous integration and continuous deployment pipeline for all components of the FinFlow application.

**Triggers:**

- Push to `main` or `develop` branches
- Pull requests targeting `main` or `develop` branches
- Manual trigger via workflow dispatch

**Key Jobs:**

1. **lint**: Performs code quality checks for each backend service and the frontend.
   - Runs ESLint for code style enforcement
   - Performs TypeScript type checking
   - Uses a matrix strategy to parallelize checks across services

2. **test-backend**: Runs unit tests for each backend service.
   - Sets up test databases (PostgreSQL, MongoDB, Redis)
   - Executes test suites for each service
   - Uploads test coverage to Codecov

3. **test-frontend**: Runs unit tests for the frontend application.
   - Executes test suites
   - Uploads test coverage to Codecov

4. **integration-tests**: Runs integration tests across services.
   - Only runs on push events or manual triggers
   - Sets up all required services (PostgreSQL, MongoDB, Redis, RabbitMQ)

5. **build**: Builds all services for production.
   - Uses a matrix strategy to build each service in parallel
   - Uploads build artifacts for later use

6. **docker**: Builds and pushes Docker images for all services.
   - Only runs on push to `main` or `develop` branches
   - Uses Docker Buildx for efficient builds
   - Implements caching for faster builds
   - Pushes images to DockerHub with appropriate tags

7. **deploy-staging**: Deploys to the staging environment.
   - Only runs on push to `develop` branch
   - Uses AWS EKS for Kubernetes deployment
   - Updates image tags in Kubernetes manifests
   - Verifies successful deployment

8. **deploy-production**: Deploys to the production environment.
   - Only runs on push to `main` branch
   - Uses AWS EKS for Kubernetes deployment
   - Updates image tags in Kubernetes manifests
   - Verifies successful deployment

**Environment Variables and Secrets:**

- `DOCKERHUB_USERNAME`: Username for DockerHub authentication
- `DOCKERHUB_TOKEN`: Token for DockerHub authentication
- `AWS_ACCESS_KEY_ID`: AWS access key for EKS access
- `AWS_SECRET_ACCESS_KEY`: AWS secret key for EKS access

**Deployment Process:**

- Uses Kubernetes for container orchestration
- Implements a blue-green deployment strategy
- Verifies deployment success with rollout status checks

### Dependency Updates (`dependency-updates.yml`)

This workflow automates the management of dependencies across all services to ensure they remain up-to-date and secure.

**Triggers:**

- Scheduled run weekly on Mondays at midnight UTC
- Manual trigger via workflow dispatch

**Key Jobs:**

1. **update-dependencies**: Updates npm dependencies for each service.
   - Uses a matrix strategy to handle each service
   - Runs tests after updates to ensure compatibility
   - Creates pull requests with dependency updates

2. **update-github-actions**: Updates GitHub Actions versions.
   - Uses Renovate bot to check for updates
   - Creates pull requests for GitHub Actions updates

3. **security-updates**: Applies security updates to dependencies.
   - Runs npm audit fix across all services
   - Creates pull requests with security fixes

**Environment Variables and Secrets:**

- `GITHUB_TOKEN`: Used for creating pull requests

**Automation Process:**

- Automatically creates separate branches for updates
- Generates detailed PR descriptions with update information
- Applies labels for easier PR categorization

### Security Scanning (`security-scan.yml`)

This workflow performs comprehensive security scanning across the codebase, dependencies, and container images.

**Triggers:**

- Push to `main` or `develop` branches
- Pull requests targeting `main` or `develop` branches
- Scheduled run weekly on Sundays at midnight UTC
- Manual trigger via workflow dispatch

**Key Jobs:**

1. **dependency-scanning**: Scans dependencies for vulnerabilities.
   - Uses npm audit to check for known vulnerabilities
   - Integrates with Snyk for deeper vulnerability scanning

2. **code-scanning**: Performs static code analysis.
   - Uses GitHub's CodeQL for advanced code analysis
   - Runs ESLint with security-focused rules

3. **secret-scanning**: Scans for exposed secrets and credentials.
   - Uses Gitleaks to detect secrets in code
   - Uses TruffleHog for additional secret detection

4. **container-scanning**: Scans container images for vulnerabilities.
   - Builds Docker images for scanning
   - Uses Trivy to scan for container vulnerabilities
   - Uploads results to GitHub Security tab

5. **compliance-checks**: Verifies compliance with security best practices.
   - Checks for security headers in API responses
   - Verifies proper CORS configuration
   - Ensures authentication middleware is in place

6. **security-report**: Generates a comprehensive security report.
   - Compiles results from all security scans
   - Uploads report as an artifact

**Environment Variables and Secrets:**

- `SNYK_TOKEN`: Authentication token for Snyk
- `GITHUB_TOKEN`: Used for GitHub Security tab integration

**Security Practices:**

- Comprehensive scanning across multiple layers
- Integration with GitHub's security features
- Regular scheduled scans for proactive security

## Workflow Interdependencies

The workflows in this project are designed with the following dependencies:

1. **CI/CD Pipeline**:
   - Internal job dependencies: Lint → Test → Build → Docker → Deploy
   - Environment-specific deployments based on branch

2. **Dependency Updates**:
   - Independent of other workflows
   - Creates pull requests that trigger the CI/CD pipeline

3. **Security Scanning**:
   - Can run independently or as part of CI/CD
   - Generates reports that inform dependency updates

This architecture ensures that:

- Code quality is verified before testing
- Tests must pass before building
- Building must succeed before deployment
- Production deployments only occur for the `main` branch
- Dependencies are regularly updated
- Security is continuously monitored

## Environment Setup

### Staging Environment

The staging environment is configured with the following components:

1. **Kubernetes Cluster**: AWS EKS cluster named `FinFlow-staging-cluster`
2. **Namespace**: `FinFlow-staging`
3. **Services**: Deployed as separate Kubernetes deployments

### Production Environment

The production environment is configured with the following components:

1. **Kubernetes Cluster**: AWS EKS cluster named `FinFlow-production-cluster`
2. **Namespace**: `FinFlow-production`
3. **Services**: Deployed as separate Kubernetes deployments
4. **URL**: https://FinFlow.abrar2030.com

### Secrets Management

The following secrets are required for the workflows to function properly:

- `DOCKERHUB_USERNAME`: Username for DockerHub authentication
- `DOCKERHUB_TOKEN`: Token for DockerHub authentication
- `AWS_ACCESS_KEY_ID`: AWS access key for EKS access
- `AWS_SECRET_ACCESS_KEY`: AWS secret key for EKS access
- `SNYK_TOKEN`: Authentication token for Snyk
- `GITHUB_TOKEN`: Automatically provided by GitHub Actions

These secrets should be configured in the repository settings under "Secrets and variables" → "Actions".

## Best Practices and Recommendations

### Adding New Services

When adding a new service to the project:

1. Add the service to the matrix in the CI/CD workflow
2. Add the service to the dependency updates workflow
3. Add the service to the security scanning workflow
4. Create appropriate Kubernetes manifests in the kubernetes directory

### Troubleshooting

Common issues and their solutions:

1. **Failed Tests**: Check the test logs for specific failures and fix the underlying issues
2. **Docker Build Failures**: Verify Dockerfile syntax and dependencies
3. **Deployment Failures**: Check AWS credentials and Kubernetes manifest validity
4. **Dependency Update Failures**: Review compatibility issues in the PR description

### Security Considerations

- Secrets are securely managed by GitHub Actions
- Regular security scans identify vulnerabilities
- Dependency updates address known security issues
- Container scanning ensures secure deployments

## Workflow Customization

To customize the workflows for specific needs:

1. **Modifying Build Parameters**: Update the build commands in the CI/CD workflow
2. **Changing Deployment Targets**: Update the Kubernetes manifests and deployment steps
3. **Adjusting Security Thresholds**: Modify the severity levels in security scanning

## Conclusion

The GitHub Actions workflows in the FinFlow project provide a robust CI/CD pipeline that ensures code quality, automates testing, and streamlines deployment across multiple application components. The dependency management and security scanning workflows further enhance the reliability and security of the application. By following the modular architecture pattern, the workflows maintain separation of concerns while efficiently utilizing GitHub Actions resources.
