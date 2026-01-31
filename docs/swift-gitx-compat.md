# SwiftGitX iOS Build Issue Report

## Summary

When cross-compiling SwiftGitX for iOS from a Linux host using [xtool](https://github.com/xtool-org/xtool) with the Darwin Swift SDK, the bundled libgit2 dependency fails to compile due to incorrect platform detection in `Package.swift`.

## Error

```
/path/to/libgit2/src/util/futils.c:1162:30: error: no member named 'st_mtim' in 'struct stat'
 1162 |                 stamp->mtime.tv_nsec == st.st_mtime_nsec &&
      |                                         ~~ ^
/path/to/libgit2/src/util/unix/posix.h:32:24: note: expanded from macro 'st_mtime_nsec'
   32 | # define st_mtime_nsec st_mtim.tv_nsec
      |                        ^
```

## Root Cause

The libgit2 `Package.swift` (from https://github.com/ibrahimcetin/libgit2) uses `#if os(macOS)` to detect Apple platforms and apply the correct configuration:

```swift
#if os(macOS)
    // Apple-specific config including GIT_NSEC_MTIMESPEC
#else
    // Linux config including GIT_NSEC_MTIM
#endif
```

**Problem**: Swift Package Manager evaluates `#if os(...)` at **package resolution time on the host machine**, not at compile time for the target platform.

When cross-compiling from Linux → iOS:
- Host: Linux
- Target: iOS
- `#if os(macOS)` evaluates to `false` on Linux host
- Linux configuration is applied (uses `st_mtim`)
- iOS uses `st_mtimespec`, causing the compile error

## Solution

Replace `#if os(...)` conditionals with `.when(platforms:)` conditions on individual settings, which ARE evaluated for the target platform:

```swift
// WRONG - evaluated on host
#if os(macOS)
    cSettings += [.define("GIT_NSEC_MTIMESPEC", to: "1")]
#else
    cSettings += [.define("GIT_NSEC_MTIM", to: "1")]
#endif

// CORRECT - evaluated for target
let applePlatforms: [Platform] = [.macOS, .iOS, .tvOS, .watchOS, .visionOS]
let linuxPlatforms: [Platform] = [.linux, .android]

let cSettings: [CSetting] = [
    .define("GIT_NSEC_MTIMESPEC", to: "1", .when(platforms: applePlatforms)),
    .define("GIT_NSEC_MTIM", to: "1", .when(platforms: linuxPlatforms)),
]
```

## Affected Files

- https://github.com/ibrahimcetin/libgit2/blob/main/Package.swift (line 128)

## Workaround

We've patched the local copy of libgit2 to use `.when(platforms:)` conditionals throughout. The patched version is in `client/LocalPackages/libgit2/`.

## Environment

- Host: Linux (Ubuntu 22.04) x64
- Target: iOS 26+
- Build tool: xtool with Darwin Swift SDK
- Swift: 6.2

## Related

- SwiftGitX: https://github.com/ibrahimcetin/SwiftGitX
- libgit2 (Swift fork): https://github.com/ibrahimcetin/libgit2
