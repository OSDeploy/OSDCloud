---
description: 'Commit message best practices and formatting guidelines'
---

# Commit Message Guidelines

This guide provides instructions for writing clear, consistent, and informative commit messages in the OSDCloud project. Well-structured commits improve code review, debugging, and project history readability.

## Commit Message Format

Follow this format for all commit messages:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type

Use one of the following types:

- **feat**: A new feature or enhancement
- **fix**: A bug fix
- **docs**: Documentation changes (README, comments, etc.)
- **refactor**: Code refactoring without feature changes or bug fixes
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **ci**: CI/CD configuration changes
- **chore**: Maintenance tasks, dependency updates, build process changes
- **style**: Code style changes (formatting, missing semicolons, etc.)
- **revert**: Revert a previous commit

### Scope

The scope specifies what part of the codebase is affected. Use lowercase, no spaces.

Examples:
- `feat(workflow): Add new deployment workflow`
- `fix(driver-packs): Resolve driver pack detection issue`
- `docs(readme): Update installation instructions`
- `refactor(pe-startup): Simplify boot sequence logic`

Optional scopes for OSDCloud:
- `workflow` - Workflow files
- `driver-packs` - Driver pack functionality
- `pe-startup` - Windows PE startup
- `deployment` - Deployment functions
- `classes` - PowerShell classes
- `catalog` - OS catalogs and metadata
- `core` - Core module functionality
- `wi-fi` - Wi-Fi functionality
- `main` - Main deployment logic

### Subject

Write a concise, imperative description of the change:

- Use the imperative mood ("add feature" not "added feature" or "adds feature")
- Do not capitalize the first letter
- Do not end with a period
- Limit to 50 characters
- Be specific and descriptive

Examples:
- `feat(workflow): add support for custom workflow definitions`
- `fix(driver-packs): resolve missing driver fallback logic`
- `docs(readme): clarify installation prerequisites`

## Commit Message Body

The body is optional but recommended for non-trivial changes. Include:

- Explain **what** and **why**, not how
- Use imperative mood
- Separate paragraphs with blank lines
- Wrap text at 72 characters
- Reference related issues: `Closes #123`, `Fixes #456`, `Related to #789`
- Include any breaking changes or migration notes

### Body Example

```
Add support for Windows 11 24H2 deployment workflow

This commit introduces a new deployment workflow for Windows 11 24H2,
including updated driver pack catalogs and OOBE customizations.

The new workflow includes:
- Enhanced hardware compatibility detection
- Optimized driver staging process
- Updated recovery partition sizing

Closes #456
Related to #789
```

## Commit Message Footer

Use the footer for:

- Closing issues: `Closes #123`, `Fixes #456`, `Resolves #789`
- Related issues: `Related to #123`
- Breaking changes: `BREAKING CHANGE: description of what changed`

Examples:

```
BREAKING CHANGE: Workflow structure changed from XML to JSON format.
All existing workflows must be migrated.

Closes #100
Related to #95, #98
```

## Full Commit Message Example

```
feat(workflow): add windows 11 25h2 deployment support

Implement deployment workflow for Windows 11 25H2 including:
- New OOBE customization profile
- Updated driver pack catalogs
- Enhanced firmware compatibility checks
- Performance optimizations for SSD deployment

This includes a new workflow definition in the latest catalog
and updated PE startup procedures.

Closes #456
Related to #450, #451
```

## Best Practices

- **Atomic Commits**: Keep commits focused on a single logical change
- **Frequent Commits**: Commit regularly with incremental progress
- **Clear History**: Write messages that make sense without context
- **Review Before Commit**: Verify changes match commit message
- **No Generic Messages**: Avoid vague messages like "update code" or "fix stuff"
- **Link to Issues**: Reference relevant GitHub issues
- **Team Communication**: Write commit messages for team collaboration

## Examples by Type

### Feature
```
feat(deployment): add unattended installation support

Add support for fully unattended installations with no user prompts.
Configuration is passed via JSON workflow definition.

Closes #123
```

### Bug Fix
```
fix(pe-startup): resolve ipconfig command timeout

The ipconfig command was hanging on some hardware configurations.
Added timeout logic with fallback to static configuration display.

Closes #234
```

### Documentation
```
docs(contributing): add commit message guidelines

Add detailed commit message formatting and best practices guide
to help contributors write clear, consistent commit messages.
```

### Refactoring
```
refactor(classes): simplify MicrosoftUpdateCatalog initialization

Extract catalog initialization logic to separate method for improved
testability and readability. No functional changes.
```

### Performance
```
perf(driver-packs): optimize driver pack detection speed

Reduce driver pack detection time by 40% through parallel processing
and caching of catalog metadata. Profiles show 2.5s improvement on
average hardware.
```

## Tools and Automation

- Use `git commit -m` for simple commits
- Use `git commit` for multi-line messages with body
- Consider commit message templates for consistency
- Review commit history with `git log --oneline`
- Use `git show` to verify commit details

## Integration with GitHub

Commit messages are automatically formatted in:
- Pull request descriptions
- GitHub release notes
- Commit history views
- Web interface logs

Write messages that read well in all contexts.
