#!/usr/bin/env coffee

opt=require 'getopt'
debugConsole=null
marker=null
command='normal'
processIndent=true
tags={}

readline=require('readline').createInterface
	input:process.stdin

T=console.log
E=console.error

appName=require('path').basename process.argv[1]

opt.setopt 'hdf:i'
opt.getopt (o,p)->
	switch o
		when 'h','?'
			command='usage'
		when 'd'
			debugConsole=console.error
		when 'f'
			marker=p[0]
		when 'i'
			processIndent=false

params=opt.params().splice 1
params.forEach (p)->
	m=p.match /^([^=]+)=(.*)/
	tags[m[1]]=m[2] if m

switch command
	when 'usage'
		pjson=require './package.json'
		version=pjson.version ? '-'

		console.log """
		#{appName} [<options>] [<TAG>=<COMMAND>]...
		version #{version}
		Copyright(c) 2017,kssfilo(https://kanasys.com/gtech/)

		Applying unix filter to parts of input stream.

		options:
			-d:debug
			-f<string>:use <string> as block seperator(default:@PARTPIPE@)
			-i:don't process indents

		example:
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
		
		inline:
			>cat example.text
			
			Name: @PARTPIPE@|sed 's/World/Earth/';Hello World@PARTPIPE@

			>cat example.text|partpipe

			Name: Hellow Earth

		tag (specify filter in command line,use = instead of |):
			>cat example.js

			var html=`
			@PARTPIPE@=MARKDOWN
			# Hello World
			This is a greeting application.
			@PARTPIPE@
			`;

			>cat example.js|partpipe 'MARKDOWN=md2html'

			var html=`
			<H1>Hello World</H1>
			<p>This is a greeting application.</p>
			`;
		"""
		process.exit 0
	else
		inputLines=[]

		readline.on 'line',(line)->inputLines.push line
		readline.on 'close',->
			require('./partpipe') inputLines.join("\n"),
				debugConsole:debugConsole
				marker:marker
				processIndent:processIndent
				tags:tags
			.then (r)->
				process.stdout.write r
			.catch (e)->
				E e