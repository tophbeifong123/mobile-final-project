# Contributing Guidelines

Thank you for contributing to the **Mobile Final Project**! To maintain code quality and smooth collaboration, please follow the guidelines below.

---

## 🌿 Git Branching Strategy

We follow a Git Flow-inspired workflow:

- `main`: Production-ready branch. Only merge via Pull Request with passing CI tests.
- `develop`: Integration branch for active features and development.
- `feat/<feature-name>`: New features (e.g., `feat/auth-login`, `feat/profile-screen`).
- `fix/<bug-name>`: Bug fixes (e.g., `fix/token-expiration`, `fix/navbar-overflow`).
- `docs/<doc-name>`: Documentation updates.
- `refactor/<refactor-name>`: Code restructuring without feature changes.

---

## 💬 Conventional Commit Messages

We strictly follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short description>
```

### Allowed Types:
- `feat`: A new feature (e.g., `feat(auth): implement google oauth login`)
- `fix`: A bug fix (e.g., `fix(api): handle 401 unauthorized gracefully`)
- `docs`: Documentation updates only
- `style`: Changes that do not affect the meaning of the code (white-space, formatting, etc.)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Code change that improves performance
- `test`: Adding missing tests or correcting existing tests
- `chore`: Changes to build process, auxiliary tools, or libraries

---

## 🛠️ Code Style & Quality Checklist

### Client (Flutter)
- Run code formatter:
  ```bash
  cd client
  dart format .
  ```
- Run analyzer:
  ```bash
  flutter analyze
  ```
- Run unit & widget tests:
  ```bash
  flutter test
  ```

### Server (NestJS)
- Run linter and formatter:
  ```bash
  cd server
  npm run lint
  npm run format
  ```
- Run unit & e2e tests:
  ```bash
  npm run test
  ```
- Build check:
  ```bash
  npm run build
  ```

---

## 🚀 Pull Request Process

1. Fork or branch from `develop`.
2. Ensure all local tests and linters pass.
3. Open a Pull Request against `develop` using the provided PR template.
4. Obtain code review approval and ensure GitHub Actions CI checks are green before merging.
