co=require 'co'
child_process=require 'child_process'

T=console.log
E=console.error
D=(opt,str)=>
	opt.debugConsole "partpipe:"+str if opt?.debugConsole?

checkSeparator=(str)=>
	!str.match /[():;]/

	#str.match /\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|/

escapeRegExp=(str)->
	str.replace(/[\-\[\]\/\{\}\*\+\.\\\^\$]/g, "\\$&")

partpipe=(input,opt={})->
	{tags={},marker=null,debugConsole=null,processIndent=true,unknownTag='bypass'}=opt

	if marker && !checkSeparator marker
		throw "you can't use '():;' for separator: #{marker}"

	marker?='(?:@PARTPIPE@)'

	D opt,"===starting partpipe process"
	D opt,"marker:#{marker}"
	D opt,"processIndent:#{processIndent}"
	D opt,"tags:#{JSON.stringify tags}"
	D opt,"unknownTag:#{unknownTag}"

	inputLines=input.split "\n"

	runProcessWithInjection=(commandLine,buffer,opt)->
		new Promise (rv,rj)->
			switch commandLine
				when 'cat'
					D opt,"command line is cat, bypassing content"
					return rv(buffer ? '')
				when ''
					D opt,"command line is null, removing content"
					return rv()
				else
					isEcho=commandLine.match /^echo (.*)$/
					if isEcho
						D opt,"command line is echo, overwriting content with #{isEcho[1]}"
						return rv(isEcho[1])

			p=child_process.exec commandLine,(err,stdout,stderr)->
				if err
					rj(stderr)
				else
					rv(stdout)
			p.stdin.write buffer if buffer!=null
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

			D opt,"block:input:"+line

			m=line.match new RegExp("^([ 	]*)#{escapeRegExp(marker)}([|=!]?)([^;]*)$")
			throw "Missing block separator for line #{beginningLineno}" if m and m[3] and state is 'buffering'
			m=null if m?[3].match new RegExp(escapeRegExp(marker)) #if inline, drop it

			D opt,"block:match:"+JSON.stringify m

			m[2]='=' if m and m[3] and m[2] is ''

			if m?[2] is '=' and !tags.hasOwnProperty(m?[3])

				switch unknownTag
					when 'remove'
						D opt,"Removing uknown tag '#{m[3]}'"
						m[2]='x'
					when 'show'
						D opt,"Showing uknown tag '#{m[3]}'"
						m[2]='|'
						m[3]='cat'
					when 'bypass'
						m=0
						state='bypass'
					else
						throw "Unknown tag '#{m[3]}' found on line #{lineno}.check argument or input syntax or use option about unknown tag. "

			switch
				when m and state is 'bypass' and m[2] in ['|','=','x','!']
					D opt,"block:found beginnning marker at line #{lineno}"
					state='buffering'
					commandLine=m[3]
					commandLine=tags[m[3]] if m[2] is '='
					commandLine='' if m[2] is 'x'
					indent=m[1]
					buffer=if m[2] isnt '!' then '' else null
					beginningLineno=lineno
					D opt,"block:command line:#{commandLine}"
					D opt,"block:current indent:[#{indent}]"
				when m and state is 'buffering'
					D opt,"block:found end marker at line #{lineno}"
					state='bypass'
					D opt,"block:command:#{if commandLine is '' then 'REMOVE' else commandLine}"
					D opt,"block:indent:#{indent.length}"
					D opt,"\n###\n#{buffer}###" if buffer!=null
					commandOutput=yield runProcessWithInjection(commandLine,buffer,opt)
					continue unless commandOutput
					commandOutput=commandOutput.replace /\n$/m,""
					D opt,"""
					block:command output:
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
					buffer+="#{line}\n" if buffer!=null
				else
					actualMarkerS="@PARTPIPE@"
					actualMarkerE="@PARTPIPE@"
					numEmarkerUsed=0
					loop
						emarkerS="@#{Math.floor(Math.random()*10000000)}@"
						emarkerE="@#{Math.floor(Math.random()*10000000)}@"
						break unless (line.match emarkerS||line.match emarkerE)

					loop
						#regex="(#{escapeRegExp(marker)})([!|=]?)([^;]+?)(;.*?)?(#{escapeRegExp(marker)})"
						regex="(#{escapeRegExp(marker)})(.+?)(#{escapeRegExp(marker)})"
						inlineRegexp=new RegExp regex

						D opt,"inline:input:"+line
						mi=line.match inlineRegexp
						if mi
							D opt,"inline:macth:"+JSON.stringify mi
							actualMarkerS=mi[1]
							actualMarkerE=mi[3]
							regex2="([!|=]?)([^;]+);?(.*?)$"
							mi=mi[2].match regex2
							D opt,"inline:2nd macth:"+JSON.stringify mi

							mi[1]='=' if mi?[1] is ''
							mi[3]=mi[3]?.replace(/^/,'') ? ''

							if mi?[1] is '=' and !tags.hasOwnProperty(mi[2])
								D opt,"found inline marker at line #{lineno}"
								D opt,"match:#{JSON.stringify(mi)}"
								switch unknownTag
									when 'remove'
										D opt,"Removing uknown tag '#{mi[2]}'"
										line=line.replace inlineRegexp,""
									when 'show'
										D opt,"Showing uknown tag '#{mi[2]}'"
										line=line.replace inlineRegexp,"#{mi[3]}"
									when 'bypass'
										D opt,"replacing remaining of line with internal maker '#{emarkerS}' '#{emarkerE}'"
										line=line.replace inlineRegexp,"#{emarkerS}#{mi[1]}#{mi[2]};#{mi[3] ? ''}#{emarkerE}"
										numEmarkerUsed++
									else
										throw "Unknown tag '#{mi[2]}' found on line #{lineno}.check argument or input syntax or use option about unknown tag. "
								continue

							commandLine=mi[2]
							commandLine=tags[mi[2]] if mi[1] is '='
							buffer=if mi[1] isnt '!' then mi[3] else null
							D opt,"inline:command:#{commandLine}"
							D opt,"inline:buffer:#{buffer}"
							commandOutput=yield runProcessWithInjection(commandLine,buffer,opt)
							commandOutput=commandOutput ? ''
							D opt,"inline:command output:#{commandOutput?.trim?()}"
							line=line.replace inlineRegexp,commandOutput.replace /\n$/,''
						else
							break

					if numEmarkerUsed>0
						D opt,"restoring internal markers to actual marker, '#{emarkerS}','#{emarkerE}'->'#{actualMarkerS}','#{actualMarkerE}'"
						D opt,"before:#{line}"
						line=line.replace new RegExp(escapeRegExp(emarkerS),'g'),actualMarkerS
						line=line.replace new RegExp(escapeRegExp(emarkerE),'g'),actualMarkerE
						D opt,"after:#{line}"

					output+="#{line}\n"


		throw "Missing block separator for line #{beginningLineno}" if state is 'buffering'
		D opt,"===partpipe process finished"
		return output

module.exports=partpipe
