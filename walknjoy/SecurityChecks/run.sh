#!/bin/sh
set -eu
root=walknjoy/walknjoy
swiftc -parse-as-library -module-cache-path /tmp/walknjoy-form-module-cache \
 "$root/Core/Validation/FormValdation.swift" "$root/Core/Validation/FormState.swift" \
 "$root/Core/State/RequestState.swift" "$root/Core/Models/Auth/ChangePassword.swift" \
 "$root/Features/Profile/Security/SecurityViewModel.swift" walknjoy/SecurityChecks/Checks.swift \
 -o /tmp/walknjoy-security-checks
/tmp/walknjoy-security-checks
