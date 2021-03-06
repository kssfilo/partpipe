### jshint esversion: 6 ###

co=require 'co'
child_process=require 'child_process'

escapeRegExp=(str)->
	str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")

partpipe=(input,options={})->
	{tags={},marker='@PARTPIPE@',debugConsole=null,processIndent=true,unknownTag='bypass'}=options

	debugConsole? "marker:#{marker}"
	debugConsole? "processIndent:#{processIndent}"
	debugConsole? "tags:#{JSON.stringify tags}"
	debugConsole? "unknownTag:#{unknownTag}"

	inputLines=input.split "\n"

	runProcessWithInjection=(commandLine,buffer)->
		new Promise (rv,rj)->
			switch commandLine
				when 'cat'
					debugConsole? "command line is cat, bypassing content"
					return rv(buffer)
				when ''
					debugConsole? "command line is null, removing content"
					return rv()
				else
					isEcho=commandLine.match /^echo (.*)$/
					if isEcho
						debugConsole? "command line is echo, overwriting content with #{isEcho[1]}"
						return rv(isEcho[1])

			p=child_process.exec commandLine,(err,stdout,stderr)->
				if err
					rj(stderr)
				else
					rv(stdout)
			p.stdin.write buffer
			p.stdin.end()

	co ->
		buffer=''
		commandLine=''
		state='bypass'
		output=''
		lineno=0
		beginningLineno=0

		for line in inputLines
			lineno++
			m=line.match new RegExp("^([ 	]*)#{escapeRegExp(marker)}([|=]?)([^;]*)$")
			throw "Missing block seperator #{marker} for line #{beginningLineno}" if m and m[3] and state is 'buffering'

			m[2]='=' if m and m[3] and m[2] is ''

			if m?[2] is '=' and !tags.hasOwnProperty(m?[3])

				switch unknownTag
					when 'remove'
						debugConsole? "Removing uknown tag '#{m[3]}'"
						m[2]='x'
					when 'show'
						debugConsole? "Showing uknown tag '#{m[3]}'"
						m[2]='|'
						m[3]='cat'
					else
						debugConsole? "Unknown tag found on line #{lineno}.Specify in cmdline like '#{m[3]}=sort'"
						m=null
			switch
				when m and state is 'bypass' and m[2] in ['|','=','x']
					debugConsole? "found beginnning marker at line #{lineno}"
					state='buffering'
					commandLine=m[3]
					commandLine=tags[m[3]] if m[2] is '='
					commandLine='' if m[2] is 'x'
					indent=m[1]
					buffer=''
					beginningLineno=lineno
				when m and state is 'buffering'

					debugConsole? "found end marker at line #{lineno}"
					state='bypass'
					debugConsole? """
						command:#{if commandLine is '' then 'REMOVE' else commandLine}
						indent:#{indent.length}
						###
						#{buffer}###
					"""

					commandOutput=yield runProcessWithInjection(commandLine,buffer)
					continue unless commandOutput
					commandOutput=commandOutput.replace /\n$/m,""
					debugConsole? """
					command output:
					###
					#{commandOutput}
					###
					"""
					if indent.length>0 and processIndent
						commandOutput=commandOutput.replace /^/mg,indent
					output+="#{commandOutput}\n"
				when !m and state is 'buffering'
					if indent.length>0 and processIndent
						line=line.replace new RegExp("^#{indent}"),''
					buffer+="#{line}\n"
				else
					loop
						emarker="@#{Math.floor(Math.random()*10000000)}@"
						break unless line.match emarker

					loop
						inlineRegexp=new RegExp("#{escapeRegExp(marker)}([|=]?)([^;]+?)(;.*?)?#{escapeRegExp(marker)}")
						mi=line.match inlineRegexp
						if mi
							mi[1]='=' if mi?[1] is ''
							mi[3]=mi[3]?.replace(/^;/,'') ? ''

							if mi?[1] is '=' and !tags.hasOwnProperty(mi[2])
								switch unknownTag
									when 'remove'
										debugConsole? "Removing uknown tag '#{mi[2]}'"
										line=line.replace inlineRegexp,""
									when 'show'
										debugConsole? "Showing uknown tag '#{mi[2]}'"
										line=line.replace inlineRegexp,"#{mi[3]}"
									else
										debugConsole? "Unknown tag found on line #{lineno}.Specify in cmdline like '#{mi[2]}=sort'"
										line=line.replace inlineRegexp,"#{emarker}#{mi[1]}#{mi[2]};#{mi[3] ? ''}#{emarker}"
								continue

							debugConsole? "found inline marker at line #{lineno}"
							commandLine=mi[2]
							commandLine=tags[mi[2]] if mi[1] is '='
							buffer=mi[3]
							debugConsole? """
								command:#{commandLine}
								buffer:#{buffer}
							"""
							commandOutput=yield runProcessWithInjection(commandLine,buffer)
							commandOutput=commandOutput ? ''
							debugConsole? "command output:#{commandOutput}"
							line=line.replace inlineRegexp,commandOutput.replace /\n$/,''
						else
							break

					line=line.replace new RegExp(escapeRegExp(emarker),'g'),marker

					output+="#{line}\n"

		throw "Missing block seperator #{marker} for line #{beginningLineno}" if state is 'buffering'
		return output

module.exports=partpipe
