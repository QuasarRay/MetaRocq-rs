# .o11y agent contract

This directory is append-only observability evidence for the unified CakeML E2E pipeline.

- Never rewrite or delete a completed `runs/<run-id>-<attempt>-<sha>/` directory.
- Never force-push trace history.
- A workflow may add only its own unique run directory and merge concurrent trace-only commits by normal fetch/rebase/push.
- Trace/process success is evidence and diagnostics, not semantic proof authority. HOL4 kernel-checked theorems remain the publication authority.
