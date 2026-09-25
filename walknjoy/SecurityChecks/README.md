Run from the repository root: `sh walknjoy/SecurityChecks/run.sh`.

Compiles the production security ViewModel, rules and DTOs with standalone test
doubles. No backend account is used or modified. Checks the three steps,
duplicate submissions, resend cooldown, OTP/token deadlines, failed verification,
confirmation matching and cleanup of sensitive values after success.

The app follows its existing ApiResponse<T> envelope for the new endpoints.
Authenticated integration against the backend remains a separate verification.
