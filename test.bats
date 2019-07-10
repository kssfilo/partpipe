#!/usr/bin/env bats

setup() {
	mkdir -p test.dir
}

teardown() {
	rm -r test.dir
}

@test "-O directory" {
	dist/cli.js -O test.dir -i test/c-test3.txt
	[ "$(cat test.dir/c-test3.txt)" = "Name:hoge aaa" ]
}

@test "-i file reading by --" {
	[ "$(dist/cli.js -- test/c-test3.txt)" = "Name:hoge aaa" ]
}

@test "-i file reading by -i" {
	[ "$(dist/cli.js -i test/c-test3.txt)" = "Name:hoge aaa" ]
}

@test "!command" {
	[ "$(cat test/nt1.txt|dist/cli.js)" = "Name:hello  aaa" ]
}

@test "Block Separator" {
	[ "$(cat test/c-test2.txt|dist/cli.js -f '=ANOTHERMARK='|tr \"\\n\" 'X' )" = "Fruits:XAppleXBananaXPineappleX" ]
}

@test "Inline" {
	[ "$(cat test/c-test3.txt|dist/cli.js)" = "Name:hoge aaa" ]
}

@test "Multiple Inline" {
	[ "$(cat test/c-test4.txt|dist/cli.js)" = "Name:hoge hee aaa" ]
}

@test "Keeping Indent(on)" {
	[ "$(cat test/c-test5.txt|dist/cli.js|tr "\n" 'x'|tr "\t" 'y')" = "Indent:xy  Applexy  Bananaxy  Pineapplex" ]
}

@test "Keeping Indent(off)" {
	[ "$(cat test/c-test5.txt|dist/cli.js -I|tr "\n" 'x'|tr "\t" 'y')" = "Indent:xApplexBananaxPineapplex" ]
}

@test "Tag" {
	[ "$(cat test/c-test6.txt|dist/cli.js 'Fluits@sort|uniq' |dist/cli.js 'Colors@sort'|tr "\n" 'x')" = "Tag:xApplexBananax=xBluexGreenxRedx" ]
}

@test "Inline Tag" {
	[ "$(cat test/c-test7.txt|dist/cli.js 'Tag1@sed "s/o/a/"'|dist/cli.js 'Tag2@sed "s/o/u/g"'|tr "\n" 'x')" = "Name:hage huu aaax" ]
}

@test "-c option(inline)" {
	[ "$(cat test/c-test7.txt|dist/cli.js -c Tag2@cat |tr "\n" 'x')" = "Name: hoo aaax" ]

}

@test "-s option(inline)" {
	[ "$(cat test/c-test7.txt|dist/cli.js -s Tag2= |tr "\n" 'x')" = "Name:hage  aaax" ]

}

@test "-w option(inline)" {
	[ "$(cat test/c-test7.txt|dist/cli.js -w Tag2 2>&1 |tr "\n" 'x')" = "abort:stdin:Unknown tag 'Tag1' found on line 1.check argument or input syntax or use option about unknown tag. x" ]

}

@test "-c option(multiline)" {
	[ "$(cat test/c-test6.txt|dist/cli.js -c 'Fluits@cat'|dist/cli.js |tr "\n" 'x')" = "Tag:xBananaxApplexBananax=x" ]
}

@test "-s option(multiline)" {
	[ "$(cat test/c-test6.txt|dist/cli.js -s Fluits= |dist/cli.js |tr "\n" 'x')" = "Tag:x=xRedxBluexGreenx" ]
}

@test "-w option(multiline)" {
	[ "$(cat test/c-test6.txt|dist/cli.js -w 'Fluits' 2>&1 |tr "\n" 'x')" = "abort:stdin:Unknown tag 'Colors' found on line 8.check argument or input syntax or use option about unknown tag. x" ]
}

@test "cat/drop shorthand" {
	[ "$(cat test/c-test7.txt|dist/cli.js Tag1= Tag2 |tr "\n" 'x')" = "Name: hoo aaax" ]

}

@test "echo shorthand" {
	[ "$(cat test/c-test7.txt|dist/cli.js Tag1=hoge Tag2=moga |tr "\n" 'x')" = "Name:hoge moga aaax" ]
}

@test "echo shorthand2" {
	[ "$(cat test/c-test10.txt |dist/cli.js Tag1=fuga Tag2=hoge Tag3= Tag4|tr "\n" 'x')" = "Name:fuga hoge aaaxxxWORLDx" ]
}

@test "Missing end separator 1" {
	[ "$(cat test/c-test8.txt|dist/cli.js Fluits Colors -s 2>&1)" = "abort:stdin:Missing block separator for line 2" ]
}

@test "Missing end separator 2" {
	[ "$(cat test/c-test9.txt|dist/cli.js Fluits Colors -s 2>&1)" = "abort:stdin:Missing block separator for line 8" ]
}

