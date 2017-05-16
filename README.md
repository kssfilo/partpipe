partpipe
==========

Command line tool to apply unix filter to parts of input stream.

```
>cat some.js

var html=`
@PARTPIPE@|md2html
# Hello World
This is a greeting application.
@PARTPIPE@
`;

var text=`
Colors:
@PARTPIPE@|sort|uniq
Blue
Red
Green
Red
Blue
@PARTPIPE@
`;
```

```
>cat some.js|partpipe

var html=`
<h1>Hello World</h1>

<p>This is a greeting application.</p>
`;

var text=`
Colors:
Blue
Green
Red
`;
```

Able to specify filter in command line (tag mode, use = instead of |)

```
>cat some.js

var html=`
@PARTPIPE@=MARKDOWN
# Hello World
This is a greeting application.
@PARTPIPE@
`;
```

```
>cat some.js|partpipe 'MARKDOWN=md2html'

var html=`
<h1>Hello World</h1>

<p>This is a greeting application.</p>
`;
```

Inline

```
>cat example.text

Name: @PARTPIPE@|sed 's/World/Earth/';Hello World@PARTPIPE@
Date: @PARTPIPE@|date;@PARTPIPE@
Name2: @PARTPIPE@=HELLO;Hello World@PARTPIPE@

>cat example.text|partpipe 'HELLO=sed "s/Hello/Good Night/"'

Name: Hello Earth
Date: Sat Apr 29 06:20:08 JST 2017
Name2: Good Night World
```

Show/Remove by tag(-c option:remove unknown tag)

```
>cat example.js

@PARTPIPE@=RELEASE;console.log('release build');@PARTPIPE@
@PARTPIPE@=DEBUG;console.log('debug build');@PARTPIPE@

>cat example.js|partpipe -c RELEASE=cat

console.log('release build');

>cat example.js|partpipe -c DEBUG=cat

console.log('debug build');
```

## Install

```
sudo npm install -g partpipe
```

## Usage

```
@SEE_NPM_README@
```

## Use as module

```
var partpipe=require("partpipe");

var input=`Colors:
@PARTPIPE@|sort|uniq
Red
Blue
Green
Blue
Red
@PARTPIPE@`;

partpipe(input).then((result)=>console.log(result));
```

## Change Log

- 0.3.x:added -s/-c option
- 0.2.x:added tag mode(@PARTPIPE@=TAG)
- 0.1.x:first release
