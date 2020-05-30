using System;
using System.Collections;

namespace JSON_Beef
{
	enum JSON_DOCUMENT_TYPE
	{
		OBJECT,
		ARRAY,
		UNKNOWN
	}

	enum JSON_TYPES
	{
		LITERAL,
		OBJECT,
		ARRAY,
		STRING,
		INTEGER,
		FLOAT
	}

	enum JSON_LITERAL
	{
		NULL,
		TRUE,
		FALSE
	}

	enum JSON_OBJECT_SEARCH_STATE
	{
		SEARCH_KEY,
		SEARCH_VALUE
	}

	enum JSON_ERRORS
	{
		INVALID_NUMBER_REPRESENTATION,
		INVALID_RETURN_TYPE,
		INDEX_OUT_OF_BOUNDS,
		KEY_NOT_FOUND
	}

	public class JSONDocument
	{
		private Dictionary<char8, char8> escapedChar;
		private String data;

		public this()
		{
			escapedChar = new Dictionary<char8, char8>();
			escapedChar.Add('\\', '\\');
			escapedChar.Add('"', '"');
			escapedChar.Add('b', '\b');
			escapedChar.Add('f', '\f');
			escapedChar.Add('n', '\n');
			escapedChar.Add('r', '\r');
			escapedChar.Add('t', '\t');
			escapedChar.Add('/', '/');
		}

		public ~this()
		{
			delete escapedChar;
		}

		public bool IsValidJson(String json)
		{
			return JSONValidator.IsValidJson(json);
		}

		public JSON_DOCUMENT_TYPE GetJsonType(String json)
		{
			let token = json[0];

			if (token == '{')
			{
				return JSON_DOCUMENT_TYPE.OBJECT;
			}
			else if (token == '[')
			{
				return JSON_DOCUMENT_TYPE.ARRAY;
			}
			else
			{
				return JSON_DOCUMENT_TYPE.UNKNOWN;
			}
		}

		public JSONArray ParseArray(String json)
		{
			var array = new JSONArray();
			ParseArray(json, ref array);
			return array;
		}

		public JSONObject ParseObject(String json)
		{
			var object = new JSONObject();
			ParseObject(json, ref object);
			return object;
		}

		private int ParseString(String json, String outString)
		{
			int i;
			outString.Clear();
			var escaped = false;

			for (i = 0; i < json.Length; i++)
			{
				let c = json[i];

				if ((c == '\\') && !escaped)
				{
					escaped = true;
				}
				else if (escapedChar.ContainsKey(c) && escaped)
				{
					outString.Append(escapedChar[c]);
					escaped = false;
				}
				else if ((c == '"') && !escaped)
				{
					break;
				}
				else
				{
					if (escaped)
					{
						outString.Append('\\');
					}
					outString.Append(c);
					escaped = false;
				}
			}

			// Todo: Implement proper error mechanism
			if (json[i] != '"')
			{
				Console.Error.WriteLine("Error: String value not terminated");
			}

			return i;
		}

		private int ParseNumber(String json, ref int outInt, ref float outFloat, ref JSON_TYPES typeParsed)
		{
			var strNum = scope String();

			typeParsed = JSON_TYPES.INTEGER;

			int i = 0;
			for (i = 0; i < json.Length; i++)
			{
				let c = json[i];

				if (c == '.')
				{
					typeParsed = JSON_TYPES.FLOAT;
					strNum.Append(c);
				}
				else if (!c.IsDigit && (c != '-') && (c != 'e') && (c != 'E') && (c != '+'))
				{
					break;
				}
				else
				{
					strNum.Append(c);
				}
			}

			// Todo: Implement proper error mechanism
			if (typeParsed == JSON_TYPES.INTEGER)
			{
				outInt = JSONUtil.ParseInt(strNum);
			}
			else if (typeParsed == JSON_TYPES.FLOAT)
			{
				outFloat = JSONUtil.ParseFloat(strNum);
			}

			// I always want the last parsed char to be a number
			return i - 1;
		}

		private int ParseLiteral(String json, ref JSON_LITERAL outLiteral)
		{
			var str = scope String();

			int i = 0;
			for (i = 0; i < json.Length; i++)
			{
				let c = json[i];

				if (!c.IsLetter)
				{
					break;
				}
				else
				{
					str.Append(c);
				}
			}

			if (str.Equals("true"))
			{
				outLiteral = .TRUE;
			}
			else if (str.Equals("false"))
			{
				outLiteral = .FALSE;
			}
			else if (str.Equals("null"))
			{
				outLiteral = .NULL;
			}
			else
			{
				// Todo: Implement proper error mechanism
				Console.Error.WriteLine("Error: Invalid literal value");
			}

			// I always want the last parsed char to be a letter
			return i - 1;
		}

		private int ParseArray(String json, ref JSONArray array)
		{
			int i = 0;
			JSON_TYPES typeParsed = JSON_TYPES.LITERAL;

			for (i = 0; i < json.Length; i++)
			{
				let c = json[i];

				if ((c == '[') && (i != 0))
				{
					let str = scope String(&json[i]);
					var outArr = scope JSONArray();
					i += ParseArray(str, ref outArr);
					array.Add(outArr);
				}
				else if (c == ']')
				{
					break;
				}
				else if (c == '"')
 				{
					 // We do not want the first char in the string to parse to be taken as a
					 // closing string token.
					 i++;
					 let str = scope String(&json[i]);
					 var outStr = scope String();
					 i += ParseString(str, outStr);
					 array.Add(outStr);
				}
				else if ((c == '-') || (c.IsNumber))
				{
					let str = scope String(&json[i]);
					int outInt = 0;
					float outFloat = 0.f;
					i += ParseNumber(str, ref outInt, ref outFloat, ref typeParsed);

					if (typeParsed == JSON_TYPES.INTEGER)
					{
						array.Add(outInt);
					}
					else if (typeParsed == JSON_TYPES.FLOAT)
					{
						array.Add(outFloat);
					}
				}
				else if (c.IsLetter)
				{
					let str = scope String(&json[i]);
					JSON_LITERAL outLiteral = .NULL;
					i += ParseLiteral(str, ref outLiteral);

					typeParsed = .LITERAL;

					array.Add(outLiteral);
				}
				else if (c == '{')
				{
					let str = scope String(&json[i]);
					var outObject = scope JSONObject();

					i += ParseObject(str, ref outObject);
					array.Add(outObject);
				}
			}

			return i;
		}

		private int ParseObject(String json, ref JSONObject object)
		{
			int i = 0;
			var lookForKey = true;
			var typeParsed = JSON_TYPES.LITERAL;
			var key = scope String();

			for (i = 0; i < json.Length; i++)
			{
				let c = json[i];

				if ((c == '{') && (!lookForKey))
				{
					i++;
					let str = scope String(&json[i]);
					var outObject = scope JSONObject();

					i += ParseObject(str, ref outObject);
					object.Add(key, outObject);
				}
				else if (c == '}')
				{
					break;
				}
				else if (c == '"')
				{
					// We do not want the first char in the string to parse to be taken as a
					// closing string token.
					i++;
					let str = scope String(&json[i]);

					if (lookForKey)
					{
						key = scope:: String();
						i += ParseString(str, key);
						lookForKey = false;
					}
					else
					{
						var outStr = scope String();
						i += ParseString(str, outStr);
						object.Add(key, outStr);
					}
				}
				else if (c.IsDigit || (c == '-') && (!lookForKey))
				{
					let str = scope String(&json[i]);
					var outInt = 0;
					var outFloat = 0.f;
					i += ParseNumber(str, ref outInt, ref outFloat, ref typeParsed);

					if (typeParsed == JSON_TYPES.INTEGER)
					{
						object.Add(key, outInt);
					}
					else if (typeParsed == JSON_TYPES.FLOAT)
					{
						object.Add(key, outFloat);
					}	
				}
				else if (c.IsLetter && (!lookForKey))
				{
					let str = scope String(&json[i]);
					var outLiteral = JSON_LITERAL.NULL;

					i += ParseLiteral(str, ref outLiteral);
					object.Add(key, outLiteral);
				}
				else if (c == '[' && (!lookForKey))
				{
					i++;
					let str = scope String(&json[i]);
					var outArr = scope JSONArray();

					i += ParseArray(str, ref outArr);
					object.Add(key, outArr);
				}
				else if (c == ',')
				{
					lookForKey = true;
				}
				/*else if (c == ':')
				{
					lookForKey = false;
				}*/
			}

			return i;
		}
	}
}
