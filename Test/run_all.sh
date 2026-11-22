#!/bin/sh
# 게임 밖에서 실행하는 모든 검사. 저장소 최상위에서 실행한다.
set -e
for f in $(find WIH WIH_EnvCheck Test -name '*.lua' | sort); do
    luac5.1 -p "$f"
done
echo "문법 검사: 통과"
lua5.1 Test/test_engine.lua
lua5.1 Test/wih_load_test.lua
lua5.1 Test/envcheck_load_test.lua
