#!/bin/bash
#
# Copyright 2021 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

# Load the test setup defined in the parent directory
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${CURRENT_DIR}/../integration_test_setup.sh" \
  || { echo "integration_test_setup.sh not found!" >&2; exit 1; }

function write_files {
  mkdir -p hello || fail "mkdir hello failed"
  cat >hello/BUILD <<EOF
cc_binary(
  name = 'hello',
  copts = [
    '-stdlib=libc++',
  ],
  linkopts = [
    '-stdlib=libc++',
  ],
  srcs = ['hello.cc'],
)
EOF

  cat >hello/hello.cc <<EOF
#include <iostream>

int main() {
  std::cout << "Hello, libc++ " << _LIBCPP_VERSION << "!" << std::endl;
}
EOF
}

function test_bazel_libc++() {
  local -r clang_tool=$(which clang)
  if [[ ! -x ${clang_tool:-/usr/bin/clang_tool} ]]; then
    echo "clang not installed. Skipping test."
    return
  fi

  write_files

  CC="${clang_tool}" bazel build //hello:hello \
    &> "${TEST_log}" || fail "Build with libc++ failed"

  bazel-bin/hello/hello || fail "the built binary failed to run"
}

run_suite "test bazel_libc++"
