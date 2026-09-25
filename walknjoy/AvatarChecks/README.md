Run from the repository root: `sh walknjoy/AvatarChecks/run.sh`.

Uses the production edit profile ViewModel and a mock service to verify delete
followed by a first successful avatar update, even when a subsequent profile GET
would be stale. Also checks that unsaved profile fields survive avatar changes.
The PhotosPicker interaction still requires an on-device or Simulator check.
