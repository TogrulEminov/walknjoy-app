#!/bin/sh
set -eu
root=walknjoy/walknjoy
swiftc -parse-as-library -module-cache-path /tmp/walknjoy-form-module-cache \
 "$root/Core/Validation/FormValdation.swift" "$root/Core/Validation/FormState.swift" \
 "$root/Core/Enums/PhoneCountry.swift" "$root/Core/Enums/RoleEnum.swift" "$root/Core/Enums/Status.swift" \
 "$root/Core/Models/File/UploadFile.swift" "$root/Core/Models/Profile/ProfileStats.swift" \
 "$root/Core/Models/Profile/ProfileModel.swift" "$root/Core/Models/Profile/AvatarResponse.swift" \
 "$root/Core/Models/Profile/UpdateProfileInput.swift" \
 "$root/Features/Profile/EditProfile/EditProfileViewModel.swift" walknjoy/AvatarChecks/Checks.swift \
 -o /tmp/walknjoy-avatar-checks
/tmp/walknjoy-avatar-checks
