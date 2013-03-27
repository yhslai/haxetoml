Haxetoml
=================

A Haxe implementation of [TOML v0.1.0](https://github.com/mojombo/toml/blob/master/versions/toml-v0.1.0.md) language.

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


