# Offline demo

Run the app with the Debug configuration. On the login screen, select **Demo ilə daxil ol**. No email, password, internet connection, or running backend is required.

The app opens a demo customer account and displays a DEMO badge. Home/search listings, listing details and availability, profile, favorites, and customer booking creation/cancellation use local fixtures. Messages, reviews, and notifications begin empty.

Demo bookings and favorites are stored in memory. Repeating a booking request with the same idempotency key returns the same booking. The demo-session flag survives relaunch; fixture changes reset after the process restarts. Use profile logout to leave demo mode, then sign in normally to use the API.

Password changes, file uploads, booking PDF tickets, provider operations, and other unsupported actions report that they are unavailable in offline demo mode. They never fall through to the API. Demo mode does not write fake tokens to Keychain or open WebSocket connections.

All demo implementation and entry points are guarded by `#if DEBUG` and excluded from Release builds. The normal login flow remains unchanged.
