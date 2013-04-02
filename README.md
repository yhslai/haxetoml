Haxetoml
=================

A Haxe implementation of [TOML v0.1.0](https://github.com/mojombo/toml/blob/master/versions/toml-v0.1.0.md) language.

Install
=================

```bash
haxelib install haxetoml
```

Usage
=================

Given `foo.toml`:

```toml
[foo]
a = 1

[foo.bar]
b = ["2", "3"]
```


You can parse it with:

```as3
import sys.io.File;

var toml = File.getContent('foo.toml');
var parser = new haxetoml.TomlParser();

var parsed = parser.parse(toml);

parsed.foo; // => 1
parsed.foo.bar[1]; // => "3"
```

There are also some shortcut methods:

```as3
var fileContent = File.getContent('foo.toml');
var parsed = haxetoml.TomlParser.parseString(fileContent);

// or this shortcut, available on neko, cpp and php:
var parsed = haxetoml.TomlParser.parseFile('foo.toml');
```

Manually Test
=================

Compile the test program first:

```
$ haxe cli_test.hxml
```

Run it:

```bash
# You can replace 'simple' with 'harder', 'empty' or whatever file name in resources/test_files
# C++
cli_test/bin/cpp/ParserTest simple
# Neko
neko cli_test/bin/ParserTest.n simple
```

To-Do
=================

* Set default value
* Compile-time parsing with marco
* Stringify

