#!/bin/bash

function style-format-GNU {
  find $PWD -name '*.h' -or -name '*.c' -or -name '*.cpp' -or -name '*.cc' | \
  xargs clang-format -i --verbose --style=GNU
}
