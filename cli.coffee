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
defaultMarker="@@@@@"
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
	i:["filename","input file name(default:stdin). you can specify multi-file like this '-i file1 -i file2 ..'  or '-- file1 file2 *.txt ..'"]
	c:"clear contents of unknown tag(default:passthrough)"
	s:"show contents of unknown tag(default:passthrough)"
	w:"error on unknown tag(default:paththrough)"
	f:["string","use <string> as block separator(default:@PARTPIPE@)"]
	I:"don't process indents"
	C:"old mode(partpipe compatible)"

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
		#{appName} [<options>] [<TAG>=<COMMAND>]... -- files1 files2 ...
		version #{version}
		Copyright(c) 2017-2019,@kssfilo(https://kanasys.com/gtech/)

		Applying unix filter to parts of input stream.

		# options:

		#{opt.getHelp optUsages}
		# example:
		    >cat example.js

		    var html=`
		    @PARTPIPE@|md2html
		    # Hello World
		    This is a greeting application.
		    @PARTPIPE@
		    `;

		    >cat example.js|partpipe

		    var html=`
		    <H1>Hello World</H1>
		    <p>This is a greeting application.</p>
		    `;
		
		# inline:
		    >cat example.text
		    
		    Name: @PARTPIPE@|sed 's/World/Earth/';Hello World@PARTPIPE@

		    >cat example.text|partpipe

		    Name: Hellow Earth

		# tag:(specify filter in command line,remove |):
		    >cat example.js

		    var html=`
		    @PARTPIPE@MARKDOWN
		    # Hello World
		    This is a greeting application.
		    @PARTPIPE@
		    `;

		    >cat example.js|partpipe 'MARKDOWN=md2html'

		    var html=`
		    <H1>Hello World</H1>
		    <p>This is a greeting application.</p>
		    `;

		# show/remove by tag
		    >cat example.js

		    @PARTPIPE@RELEASE;console.log('release build');@PARTPIPE@
		    @PARTPIPE@DEBUG;console.log('debug build');@PARTPIPE@

		    >cat example.js|partpipe -c RELEASE  #-c option:remove unknown tag/<tag>:just show content

		    console.log('release build');

		    >cat example.js|partpipe -c DEBUG

		    console.log('debug build');

		    >cat example.js|partpipe RELESE@ DEBUG  # <tag>@:remove

		    console.log('debug build');

		# replace by tag
		    >cat example.js

		    console.log("version is @PARTPIPE@VERSION@PARTPIPE@");

		    >cat example.js|partpipe VERSION@1.2.0  #<tag>@<text> replace with <text>
		    console.log('version is 1.2.0');

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


