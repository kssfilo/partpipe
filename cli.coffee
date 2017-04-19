#!/usr/bin/env coffee

opt=require 'getopt'
debugConsole=null
marker=null
command='normal'
processIndent=true

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

switch command
	when 'usage'
		pjson=require './package.json'
		version=pjson.version ? '-'

		console.log """
		#{appName} <options>
		version #{version}
		Copyright(c) 2017,kssfilo(https://kanasys.com/gtech/)

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
			.then (r)->
				process.stdout.write r
			.catch (e)->
				E e
