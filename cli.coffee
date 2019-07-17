#!/usr/bin/env coffee

opt=require '@kssfilo/getopt'
fs=require 'fs'
path=require 'path'

stdinWriteFileName='partipe.out'

debugConsole=null
marker=null
command='normal'
processIndent=true
unknownTag='bypass'
markReplace="="
markCommand="@"
defaultMarker="@PARTPIPE@"
targetDir=null
targetFile=null
inputFiles=null
tags={}

T=console.log
E=console.error
D=(str)=>debugConsole "partpipe:"+str if debugConsole

appName=path.basename process.argv[1]

optUsages=
	h:"show this usage"
	d:"debug mode"
	o:["filename","destination file name(default:stdout). use -O in multi-file mode"]
	O:["dirname","destination dir.file name will be same as input filename or #{stdinWriteFileName}. "]
	i:["filename","input file name(default:stdin). "]
	c:"clear contents of unknown tag(default:passthrough)"
	s:"show contents of unknown tag(default:passthrough)"
	w:"error on unknown tag(default:paththrough)"
	f:["string","use <string> as block separator(default:@PARTPIPE@)"]
	I:"don't process indents"
	C:"old mode(ver 0.x.x compatible)"

try
	opt.setopt 'hdo:O:i:cswf:IC'
catch e
	switch e.type
		when 'unknown'
			E "Unknown option:#{e.opt}"
		when 'required'
			E "Required parameter for option:#{e.opt}"
	process.exit 1

opt.getopt (o,p)->
	switch o
		when 'h','?'
			command='usage'
		when 'd'
			debugConsole=console.error
		when 'f'
			marker=p[0]
		when 'I'
			processIndent=false
		when 'o'
			targetFile=p[0]
		when 'O'
			targetDir=p[0]
		when 'i'
			inputFiles=p
		when 'c'
			unknownTag='remove'
		when 's'
			unknownTag='show'
		when 'w'
			unknownTag='error'
		when 'C'
			markReplace="@"
			markCommand="="
			defaultMarker="@PARTPIPE@"

params=opt.params()
D "===start"
D "=options"
D "command:#{command}"
D "marker:#{marker ? defaultMarker}"
D "processIndent:#{processIndent}"
D "unknownTag;:#{unknownTag}"
D "markReplace:#{markReplace}"
D "markCommand:#{markCommand}"
D "targetDir:#{targetDir}"
D "targetFile:#{targetFile}"

i=0
loop
	p=params[i++]
	break if typeof p is 'undefined' or p=='--'

	m=p.match new RegExp('^([^@=]+)'+markReplace+'(.*)$')
	if m
		if m[2]
			tags[m[1]]="echo #{m[2]}"
		else
			tags[m[1]]=""
	else
		m=p.match new RegExp('^([^@=]+)'+markCommand+'(.*)$')
		if m
			tags[m[1]]=m[2] if m
		else
			if p.match /^([^@=]+)$/
				tags[p]='cat'

D "tags:#{JSON.stringify tags}"
D "reamining args:#{params.slice(i)}"
if params.slice(i).length>0
	inputFiles=(inputFiles ? []).concat params.slice(i)

inputFiles?=[process.stdin]
D "input files #{(if typeof i!='string' then 'stdin' else i) for i in inputFiles}"
D "input files #{typeof i for i in inputFiles}"

try
	throw "use -O <dir> when processing multi-files" if targetFile? inputFiles.length>1
	throw "-O only works without -o" if targetFile? and targetDir?
	throw "target dir #{targetDir} not found" if targetDir? and  !(fs.statSync(targetDir)?.isDirectory())
catch e
	E e.toString()
	process.exit 1

D "start processing"

switch command
	when 'usage'
		pjson=require './package.json'
		version=pjson.version ? '-'

		console.log """
		    #{appName} [<options>] [<TAG>[=<replacetext>]]... -O <outputdir> [-- files1 files2 ...]
		    version #{version}
		    Copyright(c) 2017-2019,@kssfilo(https://kanasys.com/gtech/)
		    A command line tool,like C-preprocessor/sed/awk/perl.for embedding version/date/any data to template text/source.
		
		    Like #ifdef, you can enable/disable parts of template text/source by command line.
		
		    Additionally, applying unix filter to parts of input stream. you can write markdown / pug inside your source code.

		## Options

		#{opt.getHelp optUsages}

		you can specify multi-file like this '-i file1 -i file2 ..'  or '-- file1 file2 *.txt ..'

		## Tags
		
		    <TAG>=<replacetext>  replaces @PARTPIPE@<TAG>@PARTPIPE@ with <replacetext>. e.g. 'VERSION=1.2.0' replaces '@PARTPIPE@VERSION@PARTPIPE@'

		    <TAG>  shows   <block> of @PARTPIPE@<TAG>;<block>@PARTPIPE@ e.g. 'DEBUG' replaces '@PARTPIPE@DEBUG;console.log("debug mode")@PARTPIPE@' to 'console.log("debug mode")'
		    <TAG>= removes <block> of @PARTPIPE@<TAG>;<block>@PARTPIPE@ e.g. 'DEBUG=' replaces '@PARTPIPE@DEBUG;console.log("debug mode")@PARTPIPE@' to ''

		    <TAG>@<command> apply <command> to <block> of @PARTPIPE@TAG;<block>@PARTPIPE@ e.g. "MD@md2html" applys '@PARTPIPE@MD;# title@PARTPIPE@' to '<h1>titile</h1>'
		    # you can omit <block>. like '@PARTPIPE@DATE@PARTPIPE' in template text and 'DATE@date +%m%d%Y'. in command like. result will be '17/07/2019'

		## Examples
		
		### Replace by tag

		    $ cat example.js
		    console.log("version is @PARTPIPE@VERSION@PARTPIPE@");

		    $ partpipe VERSION=1.2.0 -O destDir/ -- example.js
		    $ cat destDir/example.js
		    console.log('version is 1.2.0');

		### Show/Remove by tag like #ifdef

		    $ cat example.js
		    @PARTPIPE@RELEASE;console.log('release build');@PARTPIPE@
		    @PARTPIPE@DEBUG;console.log('debug build');@PARTPIPE@

		    $ partpipe RELEASE DEBUG=  -O destDir/ -- example.js
		    $ cat destDir/example.js
		    console.log('release build');

		    $ partpipe RELEASE= DEBUG  -O destDir/ -- example.js
		    $ cat destDir/example.js
		    console.log('debug build');

		### multi-line

		    $ cat expample.js
		    @PARTPIPE@RELEASE
		    console.log('release build')
		    @PARTPIPE@
		    @PARTPIPE@DEBUG
		    console.log('debug build')
		    @PARTPIPE@

		    $ partpipe RELEASE= DEBUG  -O destDir/ -- example.js
		    console.log('debug build');

		### Embedding date or any command result

		    $ cat LICENSE
		    Copyright 2017-@PARTPIPE@!date +Y@PARTPIPE@ Your Name

		    $ partpipe -O destDir/ -- LICENSE
		    $ cat destDir/LICENSE
		    Copyright 2017-2019 Your Name

		if tag is start by '!', partpipe treats it as command line. you can embed date or web data(by curl/norl) or everything

		### Applying unix filter to parts of template
		
		    $ cat example.js
		    var html=`
		    @PARTPIPE@|md2html
		    # Hello World
		    This is a greeting application.
		    @PARTPIPE@
		    `;

		    $ partpipe -O destDir/ -- example.js
		    $ cat destDir/example.js
		    var html=`
		    <H1>Hello World</H1>
		    <p>This is a greeting application.</p>
		    `;

		if tag is start by '|', partpipe also treats it as command line. then inject the block to this stdin. 

		you can write markdown or pug in your program code. offcourse, any unix filter can be used such as sort / uniq.

		### Specify unix filter or any command in command line
		
		    $ cat example.js
		    var html=`
		    @PARTPIPE@MARKDOWN
		    # Hello World
		    This is a greeting application.
		    @PARTPIPE@
		    `;

		    $ partpipe 'MARKDOWN@md2html' -O destDir -- example.js
		    $ cat example.js
		    var html=`
		    <H1>Hello World</H1>
		    <p>This is a greeting application.</p>
		    `;

		you can specify filter by command line. embed like normal tag. then add '<TAG>@<commmand>' in partpipe command line.

		"""
		process.exit 0
	else

		rl=require 'readline'
		pp=require './partpipe'

		sid2name=(sid)=>
			x=inputFiles[sid]
			x='stdin' if typeof x isnt 'string'
			path.basename x

		try
			lineCallback=(sid,line)->inputLines[sid].push line
			closeCallback=(sid)->
				D "stream #{sid2name sid}:closed"
				try
					pp inputLines[sid].join("\n"),
						debugConsole:debugConsole
						marker:marker ? defaultMarker
						processIndent:processIndent
						tags:tags
						unknownTag:unknownTag
					.then (r)->
						if targetDir?
							dest=path.join(targetDir,sid2name(sid))
							D "writing #{sid2name(sid)} results to #{dest}.."
							fs.writeFileSync dest,r
						else if targetFile
							D "writing #{sid2name(sid)} results to #{targetFile} .."
							fs.writeFileSync targetFile,r
						else
							D "writing #{sid2name(sid)} results to stdout .."
							process.stdout.write r
						streamClosed null,sid
					.catch (e)->
						streamClosed "abort:#{sid2name sid}:#{e.toString()}",sid
				catch e
					streamClosed "abort:#{sid2name sid}:#{e.toString()}",sid

				return

			numClosed=0
			numError=0
			streamClosed=(e,sid)->
				if e?
					E e
					numError++

				numClosed++
				numOpening=inputLines.length-numClosed
				D "closed:#{numClosed} / opening:#{numOpening}"

				if numOpening>0
					return

				D "all streams have been closed"
				D "success:#{inputLines.length-numError} / errors:#{numError}"

				process.exit numError


			inputLines=([] for i in inputFiles)

			for input,number in inputFiles
				D "opening #{if typeof input=='object' then 'stdin' else input}"
				input=if typeof input is 'string' then fs.createReadStream input else input

				readline=rl.createInterface
					input:input

				readline.on 'line',lineCallback.bind null,number
				readline.on 'close',closeCallback.bind null,number

		catch e
			E e.toString()
			process.exit 1


