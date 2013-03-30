package haxetoml;

using haxe.Utf8;
using Lambda;

private enum TokenType {
	TkInvalid;
	TkComment;
	TkKey;
	TkKeygroup;
	TkString; TkInteger; TkFloat; TkBoolean; TkDatetime;
	TkAssignment;
	TkComma;
	TkBBegin; TkBEnd;
}

private typedef Token = {
	var type : TokenType;
	var value : String;
	var lineNum : Int;
	var colNum : Int;
}

class TomlParser {
	var tokens : Array<Token>;
	var	root : Dynamic;
	var pos = 0;

	public var currentToken(get_currentToken, null) : Token;

	/** Set up a new TomlParser instance */
	public function new() {}

	/** Parse a TOML string into a dynamic object.  Throws a String containing an error message if an error is encountered. */
	public function parse(str : String) : Dynamic {
		tokens = tokenize(str);

		//for(token in tokens)
			//trace(token);

		root = {};
		pos = 0;

		parseObj();

		return root;
	}

	function get_currentToken() {
		return tokens[pos];
	}

	function nextToken() {
		pos++;
	}

	function parseObj() {
		var keygroup = "";

		while(pos < tokens.length) {
			switch (currentToken.type) {
				case TkKeygroup:
					keygroup = decodeKeygroup(currentToken);
					createKeygroup(keygroup);
					nextToken();
				case TkKey:
					var pair = parsePair();
					setPair(keygroup, pair);
				default:
					InvalidToken(currentToken);
			}
		}
	}

	function parsePair() {
		var key = "";
		var value = {};

		if(currentToken.type == TkKey) {
			key = decodeKey(currentToken);
			nextToken();

			if(currentToken.type == TkAssignment) {
				nextToken();
				value = parseValue();
			} else {
				InvalidToken(currentToken);
			}
		} else {
			InvalidToken(currentToken);
		}

		return { key: key, value: value };
	}

	function parseValue() : Dynamic {
		var value : Dynamic = {};

		switch(currentToken.type) {
			case TkString:
				value = decodeString(currentToken);
				nextToken();
			case TkDatetime:
				value = decodeDatetime(currentToken);
				nextToken();
			case TkFloat:
				value = decodeFloat(currentToken);
				nextToken();
			case TkInteger:
				value = decodeInteger(currentToken);
				nextToken();
			case TkBoolean:
				value = decodeBoolean(currentToken);
				nextToken();
			case TkBBegin:
				value = parseArray();
			default:
				InvalidToken(currentToken);
		};

		return value;
	}

	function parseArray() {
		var array = [];

		if(currentToken.type == TokenType.TkBBegin) {
			nextToken();
			while(true) {
				if(currentToken.type != TkBEnd) {
					array.push(parseValue());
				} else {
					nextToken();
					break;
				}

				switch(currentToken.type) {
					case TkComma:
						nextToken();
					case TkBEnd:
						nextToken();
						break;
					default:
						InvalidToken(currentToken);
				}
			}
		}

		return array;
	}

	function createKeygroup(keygroup : String) {
		var keys = keygroup.split(".");
		var obj = root;

		for(key in keys) {
			var next = Reflect.field(obj, key);
			if(next == null) {
				Reflect.setField(obj, key, {});
				next = Reflect.field(obj, key);
			}
			obj = next;
		}
	}

	function setPair(keygroup : String, pair : { key : String, value : Dynamic }) {
		var keys = keygroup.split(".");
		var obj = root;

		for(key in keys) {
			obj = Reflect.field(obj, key);
		}

		Reflect.setField(obj, pair.key, pair.value);
	}

	function decode<T>(token : Token, expectedType : TokenType, decoder : String -> T) : T {
		var type = token.type;
		var value = token.value;

		if(type == expectedType)
			return decoder(value);
		else
			throw('Can\'t parse $type as $expectedType');
	}

	function decodeKeygroup(token : Token) : String {
		return decode(token, TokenType.TkKeygroup, function(v) {
			return v.substring(1, v.length - 1);
		});
	}

	function decodeString(token : Token) : String {
		return decode(token, TokenType.TkString, function(v) {
			try {
				return unescape(v);
			} catch(msg : String) {
				InvalidToken(token);
				return "";
			};
		});
	}

	function decodeDatetime(token : Token) : Date {
		return decode(token, TokenType.TkDatetime, function(v) {
			var dateStr = ~/(T|Z)/.replace(v, "");
			return Date.fromString(dateStr);
		});
	}

	function decodeFloat(token : Token) : Float {
		return decode(token, TokenType.TkFloat, function(v) {
			return Std.parseFloat(v);
		});
	}

	function decodeInteger(token : Token) : Int {
		return decode(token, TokenType.TkInteger, function(v) {
			return Std.parseInt(v);
		});
	}

	function decodeBoolean(token : Token) : Bool {
		return decode(token, TokenType.TkBoolean, function(v) {
			return v == "true";
		});
	}

	function decodeKey(token : Token) : String {
		return decode(token, TokenType.TkKey, function(v) { return v; });
	}

	function unescape(str : String) {
		var pos = 0;
		var buf = new haxe.Utf8();

		while(pos < Utf8.length(str)) {
			var c = Utf8.charCodeAt(str, pos);
			pos++;
			if(c == "\\".code) {
				c = Utf8.charCodeAt(str, pos);
				pos++;

				switch(c) {
					case "r".code: buf.addChar("\r".code);
					case "n".code: buf.addChar("\n".code);
					case "t".code: buf.addChar("\t".code);
					case "b".code: buf.addChar(8);
					case "f".code: buf.addChar(12);
					case "/".code, "\\".code, "\"".code: buf.addChar(c);
					case "u".code:
						var uc = Std.parseInt("0x" + Utf8.sub(str, pos, 4));
						buf.addChar(uc);
						pos += 4;
					default:
						throw("Invalid Escape");
				}
			} else {
				buf.addChar(c);
			}
		}

		return buf.toString();
	}

	function tokenize(str : String) {
		var tokens = new Array<Token>();
		var lines = str.split("\n");
		var a = ~/abc/;
		var patterns = [
			{ type: TokenType.TkComment, ereg: ~/^#.*$/},
			{ type: TokenType.TkKeygroup, ereg: ~/^\[.+\]/},
			{ type: TokenType.TkString, ereg: ~/^"((\\")|[^"])*"/},
			{ type: TokenType.TkDatetime, ereg: ~/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/},
			{ type: TokenType.TkFloat, ereg: ~/^-?\d+\.\d+/},
			{ type: TokenType.TkInteger, ereg: ~/^-?\d+/},
			{ type: TokenType.TkBoolean, ereg: ~/^true|false/},
			{ type: TokenType.TkAssignment, ereg: ~/^=/},
			{ type: TokenType.TkBBegin, ereg: ~/^\[/},
			{ type: TokenType.TkBEnd, ereg: ~/^\]/},
			{ type: TokenType.TkComma, ereg: ~/^,/},
			{ type: TokenType.TkKey, ereg: ~/^\S+/},
		];

		for(lineNum in 0...lines.length) {
			var line = lines[lineNum];

			var colNum = 0;
			var tokenColNum = 0;
			while(colNum < line.length) {
				while(StringTools.isSpace(line, colNum)) {
					colNum++;
				}
				var subline = line.substring(colNum);

				var matched = false;
				for(pattern in patterns) {
					var type = pattern.type;
					var ereg = pattern.ereg;

					if(ereg.match(subline)) {
						// TkKey has to be the first token of a line
						if(type == TokenType.TkKeygroup && tokenColNum != 0) {
							continue;
						}

						if(type != TokenType.TkComment) {
							tokens.push({
								type: type,
								value: ereg.matched(0),
								lineNum: lineNum,
								colNum: colNum,
							});
							tokenColNum++;
						}
						colNum += ereg.matchedPos().len;
						matched = true;

						break;
					}
				}
				if(!matched) {
					InvalidCharacter(line.charAt(colNum), lineNum, colNum);
				}
			}
		}

		return tokens;
	}

	function InvalidCharacter(char : String, lineNum : Int, colNum : Int) {
		throw('Line $lineNum Character $colNum: Invalid Character \'$char\'');
	}

	function InvalidToken(token : Token) {
		throw('Line ${token.lineNum} Character ${token.colNum}: Invalid Token \'${token.value}\'');
	}

	/** Static shortcut method to parse toml String into Dynamic object. */
	public static function parseString(toml:String)
	{
		return (new TomlParser()).parse(toml);
	}

	/** Static shortcut method to read toml file and parse into Dynamic object. */
	public static function parseFile(filename:String)
	{
		return parseString(File.getContent(filename));
	}
}
