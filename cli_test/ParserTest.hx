import sys.io.File;
import haxetoml.*;

class ParserTest {
	static function main() {
		var filename = Sys.args()[0];
		var parser = new TomlParser();
		var toml = File.getContent('resources/test_files/$filename.toml');
		var parsedToml = parser.parse(toml);

		trace(parsedToml);
	}
}
