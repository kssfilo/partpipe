#!/usr/bin/env bats

@test "Multiple Part" {
	[ "$(cat test/test.txt|dist/cli.js|tr \"\\n\" 'X' )" = "Fruits:XAppleXBananaXPineappleXXColors:XBlueXGreenXRedX" ]
}

@test "Block Separator" {
	[ "$(cat test/test2.txt|dist/cli.js -f '=ANOTHERMARK='|tr \"\\n\" 'X' )" = "Fruits:XAppleXBananaXPineappleX" ]
}

@test "Inline" {
	[ "$(cat test/test3.txt|dist/cli.js)" = "Name:hoge aaa" ]
}

@test "Multiple Inline" {
	[ "$(cat test/test4.txt|dist/cli.js)" = "Name:hoge hee aaa" ]
}

@test "Keeping Indent(on)" {
	[ "$(cat test/test5.txt|dist/cli.js|tr "\n" 'x'|tr "\t" 'y')" = "Indent:xy  Applexy  Bananaxy  Pineapplex" ]
}

@test "Keeping Indent(off)" {
	[ "$(cat test/test5.txt|dist/cli.js -i|tr "\n" 'x'|tr "\t" 'y')" = "Indent:xApplexBananaxPineapplex" ]
}
