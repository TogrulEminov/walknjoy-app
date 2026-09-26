#!/bin/sh
set -eu
root=walknjoy/walknjoy
swiftc -parse-as-library -module-cache-path /tmp/walknjoy-favorites-module-cache \
 "$root/Core/Models/Listing/ListingModel.swift" \
 "$root/Core/Models/Amenity/AmenityModel.swift" \
 "$root/Core/Models/File/UploadFile.swift" \
 "$root/Core/Models/Favorites/FavoritesModel.swift" \
 "$root/Core/State/LoadState.swift" \
 "$root/Core/State/PaginationController.swift" \
 "$root/Core/Enums/Listing.swift" \
 "$root/Core/Networking/ApiResponse.swift" \
 "$root/Features/Profile/Favorites/FavoritesViewModel.swift" \
 walknjoy/FavoritesChecks/Checks.swift -o /tmp/walknjoy-favorites-checks
/tmp/walknjoy-favorites-checks
