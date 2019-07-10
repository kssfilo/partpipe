#!/usr/bin/env bats

@test "!command" {
	[ "$(cat test/test11.txt|dist/cli.js -C)" = "Name:hello  aaa" ]
}

@test "Block Separator" {
	[ "$(cat test/test2.txt|dist/cli.js -C  -f '=ANOTHERMARK='|tr \"\\n\" 'X' )" = "Fruits:XAppleXBananaXPineappleX" ]
}

@test "Inline" {
	[ "$(cat test/test3.txt|dist/cli.js -C )" = "Name:hoge aaa" ]
}

@test "Multiple Inline" {
	[ "$(cat test/test4.txt|dist/cli.js -C )" = "Name:hoge hee aaa" ]
}

@test "Keeping Indent(on)" {
	[ "$(cat test/test5.txt|dist/cli.js -C |tr "\n" 'x'|tr "\t" 'y')" = "Indent:xy  Applexy  Bananaxy  Pineapplex" ]
}

@test "Keeping Indent(off)" {
	[ "$(cat test/test5.txt|dist/cli.js -C  -i|tr "\n" 'x'|tr "\t" 'y')" = "Indent:xApplexBananaxPineapplex" ]
}

@test "Tag" {
	[ "$(cat test/test6.txt|dist/cli.js -C  'Fluits=sort|uniq' |dist/cli.js -C  'Colors=sort'|tr "\n" 'x')" = "Tag:xApplexBananax=xBluexGreenxRedx" ]
}

@test "Inline Tag" {
	[ "$(cat test/test7.txt|dist/cli.js -C  'Tag1=sed "s/o/a/"'|dist/cli.js -C  'Tag2=sed "s/o/u/g"'|tr "\n" 'x')" = "Name:hage huu aaax" ]
}

@test "-c option(inline)" {
	[ "$(cat test/test7.txt|dist/cli.js -C  -c Tag2=cat |tr "\n" 'x')" = "Name: hoo aaax" ]

}

@test "-s option(inline)" {
	[ "$(cat test/test7.txt|dist/cli.js -C  -s Tag2= |tr "\n" 'x')" = "Name:hage  aaax" ]

}

@test "-w option(inline)" {
	[ "$(cat test/test7.txt|dist/cli.js -C  -w Tag2= 2>&1 |tr "\n" 'x')" = "abort:0:Unknown tag 'Tag1' found on line 1.check argument or input syntax or use option about unknown tag. x" ]

}

@test "-c option(multiline)" {
	[ "$(cat test/test6.txt|dist/cli.js -C  -c 'Fluits=cat'|dist/cli.js -C  |tr "\n" 'x')" = "Tag:xBananaxApplexBananax=x" ]
}

@test "-s option(multiline)" {
	[ "$(cat test/test6.txt|dist/cli.js -C  -s 'Fluits='|dist/cli.js -C  |tr "\n" 'x')" = "Tag:x=xRedxBluexGreenx" ]
}

@test "-w option(multiline)" {
	[ "$(cat test/test6.txt|dist/cli.js -C  -w 'Fluits=' 2>&1 |tr "\n" 'x')" = "abort:0:Unknown tag 'Colors' found on line 8.check argument or input syntax or use option about unknown tag. x" ]
}

@test "cat/drop shorthand" {
	[ "$(cat test/test7.txt|dist/cli.js -C  Tag1@ Tag2 |tr "\n" 'x')" = "Name: hoo aaax" ]

}

@test "echo shorthand" {
	[ "$(cat test/test7.txt|dist/cli.js -C  Tag1@hoge Tag2@moga |tr "\n" 'x')" = "Name:hoge moga aaax" ]
}

@test "echo shorthand2" {
	[ "$(cat test/test10.txt |dist/cli.js -C Tag1@fuga Tag2@hoge Tag3@ Tag4|tr "\n" 'x')" = "Name:fuga hoge aaaxxxWORLDx" ]
}

@test "Missing end separator 1" {
	[ "$(cat test/test8.txt|dist/cli.js Fluits Colors -C  -s 2>&1)" = "abort:0:Missing block separator for line 2" ]
}

@test "Missing end separator 2" {
	[ "$(cat test/test9.txt|dist/cli.js Fluits Colors -C  -s 2>&1)" = "abort:0:Missing block separator for line 8" ]
}

