# partpipe - embedding version/date/any data to template text/source.

A command line tool,like C-preprocessor/sed/awk/perl.for embedding version/date/any data to template text/source.

Like #ifdef, you can enable/disable parts of template text/source by command line.

Additionally, applying unix filter to parts of input streame. you can write markdown / pug inside your source code.

## Examples 

### Embeding verion

    $ cat example.js 
    console.log("version is @PARTPIPE@VERSION@PARTPIPE@");

    $ partpipe VERSION=1.2.0 -O destDir/ -- example.js
    $ cat destDir/example.js
    console.log('version is 1.2.0');

### Embeding current date

    $ cat LICENSE
    Copyright 2017-@PARTPIPE@!date +Y@PARTPIPE@ Your Name

    $ partpipe -O destDir/ -- LICENSE
    $ cat destDir/LICENSE
    Copyright 2017-2019 Your Name

### ifdef / endif like

    $ cat expample.js
    @PARTPIPE@RELEASE
    console.log('relase build')
    @PARTPIPE@
    @PARTPIPE@DEBUG
    console.log('debug build')
    @PARTPIPE@
    
    $ partpipe RELEASE= DEBUG  -O destDir/ -- example.js
    $ cat expmple.js
    console.log('debug build)'

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

## Install

    sudo npm install -g partpipe

## Usage

@SEE_NPM_README@

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

- 1.0.x:breaking change! @ and = are swapped on command line/adds -w option/rewriting documents/mitting ; on inline/new separator/-C mode/new debug line/multipule input mode
- 0.4.x:changes tag format to @PARTPIPE@TAG (@PARTPIPE@=TAG is also ok)
- 0.4.x:replace with text by command line (TAG@Text)
- 0.4.x:remove tag content by command line (TAG@)
- 0.4.x:show tag content by command line (TAG)
- 0.3.x:added -s/-c option
- 0.2.x:added tag mode(@PARTPIPE@=TAG)
- 0.1.x:first release
