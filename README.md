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

- 0.2.x:added tag mode(@PARTPIPE@=TAG)
- 0.1.x:first release
