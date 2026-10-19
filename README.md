# Java 21 Android 17 Termux Fix (experimental)

Experimental workaround for an OpenJDK 21 crash on Google Play Termux running Android 17 (ARM64).

## Problem

Some OpenJDK 21 tools (`javac`, `jimage`) aborted with an Android `ProtoLogNative` JNI registration error. The investigation traced a transitive dependency through `libandroid-shmem.so` to Android framework libraries.

## Proposed change

In upstream [termux/libandroid-shmem](https://github.com/termux/libandroid-shmem), change the ashmem helper implementation:

- Replace `ASharedMemory_create(name, size)` with `memfd_create(name, MFD_CLOEXEC)` followed by `ftruncate(fd, size)` (close fd and preserve errno on failure).
- Replace `ASharedMemory_getSize(fd)` with `fstat(fd, &st)`, checking `st.st_size > INT32_MAX` and setting `errno = EOVERFLOW`.
- Add `#include <sys/stat.h>`.
- Build without a direct dependency on `libandroid.so`.

## Verified on one device

- Android 17, ARM64, Google Play Termux
- OpenJDK 21.0.11: `java -version`, `javac -version`, `jimage --help`, `jlink --version`
- `javac Hello.java` and `java Hello` completed successfully
- Gradle 9.6.0 `--version`
- Offline Gradle Java project: **BUILD SUCCESSFUL** (6 seconds)

Tests were performed using an isolated `LD_LIBRARY_PATH` override, without replacing the installed library.

## Important limitations

**Experimental, not a universal fix.** Cross-process System V shared-memory semantics, API-level compatibility, and regression tests remain incomplete. Passing the above tests does not establish that the replacement is fully compatible with all users of libandroid-shmem.

## Build (Termux)

Apply the changes to the upstream source, then run:

```sh
clang -D_GNU_SOURCE -fPIC -shared -std=c11 -Wall -Wextra \
  -Wl,--version-script=exports.txt \
  shmem.c -o libandroid-shmem-test.so -llog
readelf -d libandroid-shmem-test.so | grep NEEDED
```

Do not replace the system/Termux-installed shared library until compatibility has been reviewed.

## Attribution and license

Derived from [termux/libandroid-shmem](https://github.com/termux/libandroid-shmem). Original copyright and license terms are retained in [LICENSE](LICENSE). This repository documents an experimental modification and test evidence; it is not an official Termux release.
