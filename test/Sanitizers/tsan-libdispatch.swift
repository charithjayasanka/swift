// RUN: %target-swiftc_driver %s -g -sanitize=thread %import-libdispatch -o %t_tsan-binary
// RUN: %target-codesign %t_tsan-binary
// RUN: %deflake env %env-TSAN_OPTIONS=abort_on_error=0 %target-run %t_tsan-binary 2>&1 | %FileCheck %s
// REQUIRES: executable_test
// REQUIRES: tsan_runtime
// UNSUPPORTED: OS=tvos

// FIXME: This should be covered by "tsan_runtime"; older versions of Apple OSs
// don't support TSan.
// UNSUPPORTED: remote_run

// Test ThreadSanitizer execution end-to-end with libdispatch.

import Dispatch

let sem1 = DispatchSemaphore(value: 0)
let sem2 = DispatchSemaphore(value: 0)

let q = DispatchQueue(label: "q", attributes: .concurrent)

var racy = 1

q.async {
  sem1.wait()
  racy = 2
  sem2.signal()
}
q.async {
  sem1.wait()
  racy = 3
  sem2.signal()
}

sem1.signal()
sem1.signal()
sem2.wait()
sem2.wait()

print("Done!")

// CHECK: ThreadSanitizer: data race
// CHECK: Done!
