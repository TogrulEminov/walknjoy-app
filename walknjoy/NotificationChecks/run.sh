#!/bin/sh
set -eu
root=walknjoy/walknjoy
swiftc -parse-as-library -module-cache-path /tmp/walknjoy-form-module-cache \
 "$root/Core/Validation/FormValdation.swift" "$root/Core/Validation/FormState.swift" \
 "$root/Core/State/RequestState.swift" "$root/Core/State/LoadState.swift" \
 "$root/Core/Models/Profile/Notification.swift" \
 "$root/Features/Profile/Notifications/NotificationPreferencesViewModel.swift" \
 walknjoy/NotificationChecks/Checks.swift -o /tmp/walknjoy-notification-checks
/tmp/walknjoy-notification-checks
