import sys.io.File;
import haxetoml.*;

class ParserTest {
	static function main() {
		var filename = Sys.args()[0];
		var parsedToml = TomlParser.parseFile('resources/test_files/$filename.toml');
		trace(parsedToml);
	}
}
