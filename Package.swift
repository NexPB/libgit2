// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// =============================================================================
// PLATFORM CONFIGURATION
// =============================================================================
//
// libgit2 requires different configurations for different platforms due to:
// - Different TLS/SSL backends (SecureTransport on Apple, OpenSSL on Linux)
// - Different hash implementations (CommonCrypto on Apple, builtin on Linux)
// - Different system library availability
//
// NOTE: We use .when(platforms:) for compile-time platform detection since
// #if os(...) is evaluated on the HOST, not the TARGET when cross-compiling.
//
// =============================================================================

// Common exclusions for all platforms
let excludedPaths: [String] = [
    // CMake and build system files
    "deps/llhttp/CMakeLists.txt",
    "deps/llhttp/LICENSE-MIT",
    "deps/pcre/CMakeLists.txt",
    "deps/pcre/COPYING",
    "deps/pcre/LICENCE",
    "deps/pcre/cmake/",
    "deps/pcre/config.h.in",
    "deps/xdiff/CMakeLists.txt",
    "deps/zlib/CMakeLists.txt",
    "deps/zlib/LICENSE",
    "deps/ntlmclient/CMakeLists.txt",
    "src/libgit2/CMakeLists.txt",
    "src/libgit2/experimental.h.in",
    "src/libgit2/git2.rc",
    "src/libgit2/config.cmake.in",
    "src/util/CMakeLists.txt",
    "src/util/git2_features.h.in",

    // Windows-specific files (never used on Unix-like systems)
    "src/util/hash/win32.c",
    "src/util/hash/win32.h",
    "src/util/win32",

    // mbedTLS backend (not used on any platform)
    "src/util/hash/mbedtls.c",
    "src/util/hash/mbedtls.h",
    "deps/ntlmclient/crypt_mbedtls.c",
    "deps/ntlmclient/crypt_mbedtls.h",
    "deps/ntlmclient/crypt_builtin_md4.c",

    // OpenSSL hash backend (not used - we use CommonCrypto on Apple, builtin on Linux)
    "src/util/hash/openssl.c",
    "src/util/hash/openssl.h",

    // Unicode iconv backend - we use UNICODE_BUILTIN instead
    "deps/ntlmclient/unicode_iconv.c",
    "deps/ntlmclient/unicode_iconv.h",

    // OpenSSL NTLM crypto - only for Linux but requires OpenSSL headers
    // We exclude this and use CommonCrypto on Apple platforms
    // On Linux it would need OpenSSL installed, which we don't want to require
    "deps/ntlmclient/crypt_openssl.c",
    "deps/ntlmclient/crypt_openssl.h",

    // Builtin SHA1 (collision detection) - exclude to use CommonCrypto on Apple
    // These files have compile-time guards but excluding avoids issues
    "src/util/hash/builtin.c",
    "src/util/hash/builtin.h",
    "src/util/hash/collisiondetect.c",
    "src/util/hash/collisiondetect.h",
    "src/util/hash/rfc6234",
    "src/util/hash/sha1dc",
]

// Apple platforms
let applePlatforms: [Platform] = [.macOS, .iOS, .tvOS, .watchOS, .visionOS]
let linuxPlatforms: [Platform] = [.linux, .android]

// Platform-specific C settings using .when(platforms:) for cross-compilation support
let cSettings: [CSetting] = [
    // Header search paths
    .headerSearchPath("deps/llhttp"),
    .headerSearchPath("deps/pcre"),
    .headerSearchPath("deps/xdiff"),
    .headerSearchPath("deps/zlib"),
    .headerSearchPath("deps/ntlmclient"),
    .headerSearchPath("src/libgit2"),
    .headerSearchPath("src/util"),

    // Core configuration
    .define("LIBGIT2_NO_FEATURES_H"),
    .define("GIT_THREADS", to: "1"),
    .define("GIT_THREADS_PTHREADS", to: "1"),
    .define("GIT_ARCH_64", to: "1"),

    // PCRE regex configuration (builtin)
    .define("GIT_REGEX_BUILTIN", to: "1"),
    .define("SUPPORT_PCRE8", to: "1"),
    .define("HAVE_STDINT_H", to: "1"),
    .define("HAVE_INTTYPES_H", to: "1"),
    .define("HAVE_MEMMOVE", to: "1"),
    .define("HAVE_STRERROR", to: "1"),
    .define("LINK_SIZE", to: "2"),
    .define("PARENS_NEST_LIMIT", to: "250"),
    .define("MATCH_LIMIT", to: "10000000"),
    .define("MATCH_LIMIT_RECURSION", to: "10000000"),
    .define("NEWLINE", to: "10"),
    .define("NO_RECURSE", to: "1"),
    .define("POSIX_MALLOC_THRESHOLD", to: "10"),
    .define("BSR_ANYCRLF", to: "0"),
    .define("MAX_NAME_SIZE", to: "32"),
    .define("MAX_NAME_COUNT", to: "10000"),

    // SSH transport
    .define("GIT_SSH", to: "1", .when(platforms: [.macOS, .iOS, .linux, .android])),
    .define("GIT_SSH_EXEC", to: "1", .when(platforms: [.macOS, .iOS, .linux, .android])),

    // HTTP configuration
    .define("GIT_HTTPS", to: "1"),
    .define("GIT_HTTPPARSER_BUILTIN", to: "1"),

    // I/O configuration
    .define("GIT_IO_POLL", to: "1"),

    // Nanosecond timestamp support
    .define("GIT_NSEC", to: "1"),
    .define("GIT_FUTIMENS", to: "1"),

    // NTLM authentication (builtin)
    .define("GIT_AUTH_NTLM", to: "1"),
    .define("GIT_AUTH_NTLM_BUILTIN", to: "1"),
    .define("NTLM_STATIC", to: "1"),
    .define("UNICODE_BUILTIN", to: "1"),

    // Compression (builtin zlib)
    .define("GIT_COMPRESSION_BUILTIN", to: "1"),

    // =========================================================================
    // APPLE PLATFORM CONFIGURATION
    // =========================================================================

    // qsort variant (BSD-style on Apple)
    .define("GIT_QSORT_BSD", .when(platforms: applePlatforms)),

    // HTTPS via SecureTransport (Apple)
    .define("GIT_SECURE_TRANSPORT", to: "1", .when(platforms: applePlatforms)),

    // Hash implementations via CommonCrypto (Apple)
    .define("GIT_SHA1_COMMON_CRYPTO", to: "1", .when(platforms: applePlatforms)),
    .define("GIT_SHA256_COMMON_CRYPTO", to: "1", .when(platforms: applePlatforms)),

    // NTLM crypto via CommonCrypto (Apple)
    .define("CRYPT_COMMONCRYPTO", .when(platforms: applePlatforms)),

    // Nanosecond support via mtimespec (Apple-style: st_mtimespec)
    .define("GIT_NSEC_MTIMESPEC", to: "1", .when(platforms: applePlatforms)),

    // Internationalization via iconv (Apple)
    .define("GIT_I18N", to: "1", .when(platforms: applePlatforms)),
    .define("GIT_I18N_ICONV", to: "1", .when(platforms: applePlatforms)),

    // Restricted platforms
    .define("GIT_NO_PROCESS_SPAWN", .when(platforms: [.tvOS, .watchOS])),

    // =========================================================================
    // LINUX PLATFORM CONFIGURATION
    // Note: Linux support is limited since we exclude OpenSSL-dependent files
    // =========================================================================

    // Enable GNU extensions (required for qsort_r, etc.)
    .define("_GNU_SOURCE", .when(platforms: linuxPlatforms)),

    // qsort variant (GNU-style on Linux)
    .define("GIT_QSORT_GNU", .when(platforms: [.linux])),

    // Nanosecond support via mtim (Linux-style: st_mtim)
    .define("GIT_NSEC_MTIM", to: "1", .when(platforms: linuxPlatforms)),

    // Random number generation (Linux)
    .define("GIT_RAND_GETENTROPY", to: "1", .when(platforms: [.linux])),
    .define("GIT_RAND_GETLOADAVG", to: "1", .when(platforms: [.linux])),
]

// Linker settings
let linkerSettings: [LinkerSetting] = [
    // Apple platforms
    .linkedLibrary("iconv", .when(platforms: applePlatforms)),

    // Linux platforms
    .linkedLibrary("z", .when(platforms: linuxPlatforms)),
    .linkedLibrary("dl", .when(platforms: linuxPlatforms)),
    .linkedLibrary("pthread", .when(platforms: linuxPlatforms)),
]

// =============================================================================
// PACKAGE DEFINITION
// =============================================================================

let package = Package(
    name: "libgit2",
    products: [
        .library(name: "libgit2", targets: ["libgit2"])
    ],
    targets: [
        .target(
            name: "libgit2",
            path: ".",
            exclude: excludedPaths,
            sources: [
                "deps/llhttp",
                "deps/pcre",
                "deps/xdiff",
                "deps/zlib",
                "deps/ntlmclient",
                "src/libgit2",
                "src/util",
            ],
            publicHeadersPath: "include",
            cSettings: cSettings,
            linkerSettings: linkerSettings
        )
    ]
)
