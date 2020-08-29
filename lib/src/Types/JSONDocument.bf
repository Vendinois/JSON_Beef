using System;
using System.Collections;
using JSON_Beef.Util;

namespace JSON_Beef.Types
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
		KEY_NOT_FOUND,
		STRING_NOT_TERMINATED,
		INVALID_LITERAL_VALUE,
		INVALID_OBJECT,
		INVALID_ARRAY,
		INVALID_JSON_STRING,
		UNKNOWN_ERROR,
		INVALID_TYPE,
		CANNOT_CONVERT_SIGNED_TO_UNSIGNED
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

		public Result<JSONArray, JSON_ERRORS> ParseArray(String json)
		{
			var array = new JSONArray();
			if (ParseArrayInternal(json, ref array) case .Err(let err))
			{
				delete array;
				return .Err(err);
			}
			return array;
		}

		public Result<void, JSON_ERRORS> ParseArray(String json, ref JSONArray array)
		{
			if (ParseArrayInternal(json, ref array) case .Err(let err))
			{
				return .Err(err);
			}

			return .Ok;
		}

		public Result<JSONObject, JSON_ERRORS> ParseObject(String json)
		{
			var object = new JSONObject();
			if (ParseObjectInternal(json, ref object) case .Err(let err))
			{
				delete object;
				return .Err(err);
			}
			return object;
		}

		public Result<void, JSON_ERRORS> ParseObject(String json, ref JSONObject object)
		{
			if (ParseObjectInternal(json, ref object) case .Err(let err))
			{
				return .Err(err);
			}

			return .Ok;
		}

		private Result<int, JSON_ERRORS> ParseString(String json, String outString)
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

			if (json[i] != '"')
			{
				return .Err(.STRING_NOT_TERMINATED);
			}

			return .Ok(i);
		}

		private Result<int, JSON_ERRORS> ParseNumber(String json, String outStr)
		{
			if (!JSONValidator.IsValidNumber(json))
			{
				return .Err(.INVALID_NUMBER_REPRESENTATION);
			}

			var strNum = scope String();
			outStr.Clear();

			int i = 0;
			for (i = 0; i < json.Length; i++)
			{
				let c = json[i];

				if (c == '.')
				{
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

			outStr.Set(strNum);

			// I always want the last parsed char to be a number
			return .Ok(i - 1);
		}

		private Result<int, JSON_ERRORS> ParseLiteral(String json, String outStr)
		{
			if (!JSONValidator.IsValidLiteral(json))
			{
				return .Err(.INVALID_LITERAL_VALUE);
			}

			var str = scope String();
			outStr.Clear();

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

			outStr.Set(str);

			// I always want the last parsed char to be a letter
			return .Ok(i - 1);
		}

		private Result<int, JSON_ERRORS> ParseArrayInternal(String json, ref JSONArray array)
		{
			int i = 0;

			for (i = 0; i < json.Length; i++)
			{
				let c = json[i];

				if ((c == '[') && (i != 0))
				{
					let str = scope String(&json[i]);
					var outArr = scope JSONArray();
					let res = ParseArrayInternal(str, ref outArr);

					switch (res)
					{
					case .Err(let err):
						return .Err(err);
					default:
						i += res.Get();
					}

					array.Add<JSONArray>(outArr);
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
					let res = ParseString(str, outStr);

					switch (res)
					{
					case .Err(let err):
						return .Err(err);
					case .Ok(let val):
						i += val;
					}

					array.Add<String>(outStr);
				}
				else if ((c == '-') || (c.IsNumber))
				{
					let str = scope String(&json[i]);
					var outStr = scope String();
					let res = ParseNumber(str, outStr);

					switch (res)
					{
					case .Err(let err):
						return .Err(err);
					case .Ok(let val):
						i += val;
					}

					if (outStr.Contains('.'))
					{
						array.Add<float>(outStr);
					}
					else
					{
						array.Add<int64>(outStr);
					}
				}
				else if (c.IsLetter)
				{
					let str = scope String(&json[i]);
					var outStr = scope String();
					let res = ParseLiteral(str, outStr);

					switch (res)
					{
					case .Err(let err):
						return .Err(err);
					case .Ok(let val):
						i += val;
					}

					if (outStr.Equals("null"))
					{
						array.Add<Object>(null);
					}
					else
					{
						array.Add<bool>(outStr);
					}
				}
				else if (c == '{')
				{
					let str = scope String(&json[i]);
					var outObject = scope JSONObject();

					let res = ParseObjectInternal(str, ref outObject);

					switch (res)
					{
					case .Err(let err):
						return .Err(err);
					default:
						i += res.Get();
					}

					array.Add<JSONObject>(outObject);
				}
			}

			return .Ok(i);
		}

		private Result<int, JSON_ERRORS> ParseObjectInternal(String json, ref JSONObject object)
		{
			int i = 0;
			var lookForKey = true;
			//var typeParsed = JSON_TYPES.LITERAL;
			var key = scope String();

			for (i = 0; i < json.Length; i++)
			{
				let c = json[i];

				if ((c == '{') && (!lookForKey))
				{
					i++;
					let str = scope String(&json[i]);
					var outObject = scope JSONObject();

					let res = ParseObjectInternal(str, ref outObject);

					switch (res)
					{
					case .Err(let err):
						return .Err(err);
					default:
						i += res.Get();
					}

					object.Add<JSONObject>(key, outObject);
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
						let res = ParseString(str, key);

						switch (res)
						{
						case .Err(let err):
							return .Err(err);
						case .Ok(let val):
							i += val;
						}

						lookForKey = false;
					}
					else
					{
						var outStr = scope String();
						let res = ParseString(str, outStr);

						switch (res)
						{
						case .Err(let err):
							return .Err(err);
						case .Ok(let val):
							i += val;
						}

						object.Add<String>(key, outStr);
					}
				}
				else if (c.IsDigit || (c == '-') && (!lookForKey))
				{
					let str = scope String(&json[i]);
					var outStr = scope String();
					let res = ParseNumber(str, outStr);

					switch (res)
					{
					case .Err(let err):
						return .Err(err);
					case .Ok(let val):
						i += val;
					}

					if (outStr.Contains('.'))
					{
						object.Add<float>(key, outStr);
					}
					else
					{
						object.Add<int64>(key, outStr);
					}
				}
				else if (c.IsLetter && (!lookForKey))
				{
					let str = scope String(&json[i]);
					var outStr = scope String();

					let res = ParseLiteral(str, outStr);

					switch (res)
					{
					case .Err(let err):
						return .Err(err);
					case .Ok(let val):
						i += val;
					}

					if (outStr.Equals("null"))
					{
						object.Add<Object>(key, null);
					}
					else
					{
						object.Add<bool>(key, outStr);
					}
				}
				else if (c == '[' && (!lookForKey))
				{
					//i++;
					let str = scope String(&json[i]);
					var outArr = scope JSONArray();

					let res = ParseArrayInternal(str, ref outArr);

					switch (res)
					{
					case .Err(let err):
						return .Err(err);
					default:
						i += res.Get();
					}

					object.Add<JSONArray>(key, outArr);
				}
				else if (c == ',')
				{
					lookForKey = true;
				}
			}

			return .Ok(i);
		}
	}
}
