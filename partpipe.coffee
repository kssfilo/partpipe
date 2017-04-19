### jshint esversion: 6 ###

co=require 'co'
child_process=require 'child_process'

escapeRegExp=(str)->
	str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")

partpipe=(input,options={})->
	{marker='@PARTPIPE@',debugConsole=null,processIndent=true}=options

	debugConsole? "marker:#{marker}"

	inputLines=input.split "\n"

	runProcessWithInjection=(commandLine,buffer)->
		new Promise (rv,rj)->
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

		for line in inputLines
			lineno++
			m=line.match new RegExp("^([ 	]*)#{escapeRegExp(marker)}\\|?([^;]*)$")
			switch
				when m and state is 'bypass'
					debugConsole? "found beginnning marker at line #{lineno}"
					state='buffering'
					commandLine=m[2]
					indent=m[1]
					buffer=''
				when m and state is 'buffering'
					debugConsole? "found end marker at line #{lineno}"
					state='bypass'
					debugConsole? """
						command:#{commandLine}
						indent:#{indent.length}
						###
						#{buffer}###
					"""

					commandOutput=yield runProcessWithInjection(commandLine,buffer)
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
						inlineRegexp=new RegExp("#{escapeRegExp(marker)}\\|([^;]+);(.*?)#{escapeRegExp(marker)}")
						mi=line.match inlineRegexp
						if mi
							debugConsole? "found inline marker at line #{lineno}"
							commandLine=mi[1]
							buffer=mi[2]
							debugConsole? """
								command:#{commandLine}
								buffer:#{buffer}
							"""
							commandOutput=yield runProcessWithInjection(commandLine,buffer)
							debugConsole? "command output:#{commandOutput}"
							line=line.replace inlineRegexp,commandOutput.replace /\n$/,''
						else
							break

					output+="#{line}\n"

		return output

module.exports=partpipe
