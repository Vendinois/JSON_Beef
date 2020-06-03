using System;
using System.Collections;
using System.IO;
using JSON_Beef;

namespace JSON_Beef_Test
{
	class Program
	{
		static void Main()
		{
			Console.WriteLine("Test suit for JSON Beef.");

			Console.WriteLine("Testing validation rules:");

			TestStringsValidation();
			TestNumbersValidation();
			TestLiteralsValidation();
			TestArraysValidation();
			TestObjectsValidation();
			TestJsonFileValidation();
			TestJsonUtil();
			TestJsonParsing();
			TestJsonSerializing();

			Console.WriteLine("Press any [enter] to exit.");
			Console.In.Read();
		}

		static void TestStringsValidation()
		{
			Runtime.Assert(JSONValidator.IsValidString("\"\""), "String Validation Test #1 failed");
			Runtime.Assert(JSONValidator.IsValidString("\"abcdefghijklmnopqrstuvwxyz1234567890-!@#$%^&*()_+[]{};:'?.><,/\""), "String Validation Test #2 failed");
			Runtime.Assert(JSONValidator.IsValidString("\"\r\n\t\f\b\u{0063}\""), "String Validation Test #3 failed");
			Runtime.Assert(JSONValidator.IsValidString("\"\a\"") == false, "String Validation Test #4 failed");

			Console.WriteLine("Strings validation tests passed");
		}

		static void TestNumbersValidation()
		{
			Runtime.Assert(JSONValidator.IsValidNumber("42"), "Numbers Validation Test #1 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("-42"), "Numbers Validation Test #2 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("42.42"), "Numbers Validation Test #3 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("-42.42"), "Numbers Validation Test #4 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("42e3"), "Numbers Validation Test #5 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("42e+3"), "Numbers Validation Test #6 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("42e-3"), "Numbers Validation Test #7 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("-42e3"), "Numbers Validation Test #8 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("-42e+3"), "Numbers Validation Test #9 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("-42e-3"), "Numbers Validation Test #10 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("4.2e+3"), "Numbers Validation Test #11 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("-4.2e+3"), "Numbers Validation Test #12 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("4.2e+3.3") == false, "Numbers Validation Test #13 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("4.2.3") == false, "Numbers Validation Test #14 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("4.2e-3.3") == false, "Numbers Validation Test #15 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("4.2e3.3") == false, "Numbers Validation Test #16 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("4.2+3.3") == false, "Numbers Validation Test #17 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("4.2-3.3") == false, "Numbers Validation Test #18 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("--4.2") == false, "Numbers Validation Test #19 failed");
			Runtime.Assert(JSONValidator.IsValidNumber(".43") == false, "Numbers Validation Test #20 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("e43") == false, "Numbers Validation Test #21 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("-e43") == false, "Numbers Validation Test #22 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("+e43") == false, "Numbers Validation Test #23 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("+") == false, "Numbers Validation Test #24 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("-") == false, "Numbers Validation Test #25 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("e43") == false, "Numbers Validation Test #26 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("\r\n\t\f\b\u{0063}") == false, "Numbers Validation Test #27 failed");
			Runtime.Assert(JSONValidator.IsValidNumber("true") == false, "Numbers Validation Test #28 failed");

			Console.WriteLine("Numbers validation tests passed");
		}

		static void TestLiteralsValidation()
		{
			Runtime.Assert(JSONValidator.IsValidLiteral("true"), "Literals Validation Test #1 failed");
			Runtime.Assert(JSONValidator.IsValidLiteral("false"), "Literals Validation Test #2 failed");
			Runtime.Assert(JSONValidator.IsValidLiteral("null"), "Literals Validation Test #3 failed");
			Runtime.Assert(JSONValidator.IsValidLiteral("test") == false, "Literals Validation Test #4 failed");
			Runtime.Assert(JSONValidator.IsValidLiteral("42") == false, "Literals Validation Test #5 failed");
			Runtime.Assert(JSONValidator.IsValidLiteral("[]") == false, "Literals Validation Test #6 failed");
			Runtime.Assert(JSONValidator.IsValidLiteral("{}") == false, "Literals Validation Test #7 failed");

			Console.WriteLine("Literals validation tests passed");
		}

		static void TestArraysValidation()
		{
			Runtime.Assert(JSONValidator.IsValidArray("[]"), "Arrays Validation Test #1 failed");
			Runtime.Assert(JSONValidator.IsValidArray("[42,\"toto\", true]"), "Arrays Validation Test #2 failed");
			Runtime.Assert(JSONValidator.IsValidArray("[{}]"), "Arrays Validation Test #3 failed");
			Runtime.Assert(JSONValidator.IsValidArray("[[]]"), "Arrays Validation Test #4 failed");
			Runtime.Assert(JSONValidator.IsValidArray("[,,,,]") == false, "Arrays Validation Test #5 failed");
			Runtime.Assert(JSONValidator.IsValidArray("[,]") == false, "Arrays Validation Test #6 failed");
			Runtime.Assert(JSONValidator.IsValidArray("[42,]") == false, "Arrays Validation Test #7 failed");
			Runtime.Assert(JSONValidator.IsValidArray("[{}") == false, "Arrays Validation Test #8 failed");
			Runtime.Assert(JSONValidator.IsValidArray("[") == false, "Arrays Validation Test #9 failed");
			Runtime.Assert(JSONValidator.IsValidArray("[\"t") == false, "Arrays Validation Test #10 failed");

			Console.WriteLine("Arrays validation tests passed");
		}

		static void TestObjectsValidation()
		{
			Runtime.Assert(JSONValidator.IsValidObject("{}"), "Objects Validation Test #1 failed");
			Runtime.Assert(JSONValidator.IsValidObject("{\"key\":\"a string value\", \"another key\": 42}"), "Objects Validation Test #2 failed");
			Runtime.Assert(JSONValidator.IsValidObject("{\"key\":[], \"another key\": {}}"), "Objects Validation Test #3 failed");
			Runtime.Assert(JSONValidator.IsValidObject("{\"key\":\"a string value\", \"another key\":}") == false, "Objects Validation Test #4 failed");
			Runtime.Assert(JSONValidator.IsValidObject("{\"key\":\"a string value\", 'another key': 42") == false, "Objects Validation Test #5 failed");
			Runtime.Assert(JSONValidator.IsValidObject("{\"key\":\"a string value\", \"another key") == false, "Objects Validation Test #6 failed");

			Console.WriteLine("Objects validation tests passed");
		}

		static void TestJsonFileValidation()
		{
			var data = scope String();
			var gotData = GetValidArrayData(data);

			if (gotData)
			{
				Runtime.Assert(JSONValidator.IsValidJson(data), "Json file validation test #1 failed");
			}
			else
			{
				Runtime.Assert(false, "Failed loading array data");
			}

			gotData = GetValidObjectData(data);
			if (gotData)
			{
				Runtime.Assert(JSONValidator.IsValidJson(data), "Json file validation test #2 failed");
			}
			else
			{
				Runtime.Assert(false, "Failed loading object data");
			}

			Console.WriteLine("Json file validation tests passed");
		}

		static bool GetValidArrayData(String outData)
		{
			outData.Clear();
			var exePath = scope String();
			Environment.GetExecutableFilePath(exePath);

			var dir = scope String();
			Path.GetDirectoryPath(exePath, dir);

			var file = scope String();
			Path.Join(dir, "json\\valid_array.json", file);

			let sr = scope StreamReader();
			let isOpened = sr.Open(file);
		
			switch (isOpened)
			{
			case .Err(.NotFile), .Err(.NotFound), .Err(.SharingViolation), .Err(.Unknown):
				sr.Dispose();
				return false;
			default:
				sr.ReadToEnd(outData);
				sr.Dispose();
				return true;
			}
		}

		static bool GetValidObjectData(String outData)
		{
			outData.Clear();
			var exePath = scope String();
			Environment.GetExecutableFilePath(exePath);

			var dir = scope String();
			Path.GetDirectoryPath(exePath, dir);

			var file = scope String();
			Path.Join(dir, "json\\valid_object.json", file);

			let sr = scope StreamReader();
			let isOpened = sr.Open(file);

			switch (isOpened)
			{
			case .Err(.NotFile), .Err(.NotFound), .Err(.SharingViolation), .Err(.Unknown):
				sr.Dispose();
				return false;
			default:
				sr.ReadToEnd(outData);
				sr.Dispose();
				return true;
			}
		}

		static void TestJsonUtil()
		{
			Runtime.Assert(JSONUtil.ParseInt("42") == 42, "JSONUtil test #1 failed");
			Runtime.Assert(JSONUtil.ParseInt("42e5") == 4200000, "JSONUtil test #2 failed");
			Runtime.Assert(JSONUtil.ParseInt("-42e3") == -42000, "JSONUtil test #3 failed");

			var res = JSONUtil.ParseInt("4.2");
			Runtime.Assert(ValidError(ref res), "JSONUtil test #4 failed");

			res = JSONUtil.ParseInt("42e-3");
			Runtime.Assert(ValidError(ref res), "JSONUtil test #5 failed");

			Runtime.Assert(JSONUtil.ParseFloat("42") == 42f, "JSONUtil test #6 failed");
			Runtime.Assert(JSONUtil.ParseFloat("-42") == -42f, "JSONUtil test #7 failed");
			Runtime.Assert(JSONUtil.ParseFloat("4.2") == 4.2f, "JSONUtil test #8 failed");
			Runtime.Assert(JSONUtil.ParseFloat("-4.2") == -4.2f, "JSONUtil test #9 failed");
			Runtime.Assert(JSONUtil.ParseFloat("42e3") == 42000f, "JSONUtil test #10 failed");
			Runtime.Assert(JSONUtil.ParseFloat("-42e3") == -42000f, "JSONUtil test #11 failed");
			Runtime.Assert(JSONUtil.ParseFloat("4.2e3") == 4200f, "JSONUtil test #12 failed");
			Runtime.Assert(JSONUtil.ParseFloat("-4.2e3") == -4200f, "JSONUtil test #13 failed");
			Runtime.Assert(JSONUtil.ParseFloat("4.2e-3") == 0.0042f, "JSONUtil test #14 failed");
			Runtime.Assert(JSONUtil.ParseFloat("-4.2e-3") == -0.0042f, "JSONUtil test #15 failed");

			Console.WriteLine("JSONUtil tests passed");
		}

		static bool ValidError(ref Result<int, JSON_ERRORS> res)
		{
			switch (res)
			{
			case .Err(.INVALID_NUMBER_REPRESENTATION):
				return true;
			default:
				return false;
			}
		}

		static bool FloatEquals(float a, float b)
		{
			return Math.Abs(a - b) < Float.Epsilon;
		}

		static void TestJsonParsing()
		{
			var data = scope String();
			var gotData = GetValidArrayData(data);

			if (gotData)
			{
				let doc = scope JSONDocument();
				if (JSONValidator.IsValidJson(data) && (doc.GetJsonType(data) == .ARRAY))
				{
					let array = doc.ParseArray(data);
					ValidateArrayFile(array);
					delete array.Get();
				}
			}

			gotData = GetValidObjectData(data);

			if (gotData)
			{
				let doc = scope JSONDocument();
				if (JSONValidator.IsValidJson(data) && (doc.GetJsonType(data) == .OBJECT))
				{
					let object = doc.ParseObject(data);
					ValidateObject(object);
					delete object.Get();
				}
			}

			Console.WriteLine("JSON Parsing tests passed");
		}

		static void ValidateArrayFile(JSONArray array)
		{
			ValidateFirstArray(array);
			ValidateObject(array);
		}

		static void ValidateFirstArray(JSONArray array)
		{
			var arr = array.Get<JSONArray>(0);
			Runtime.Assert(IsValidType<JSONArray>(ref arr), "JSON Parsing failed: Invalid type first value in array");
			let v = arr.Get();

			Runtime.Assert(v.Count == 12, "JSON Parsing failed: invalid count in first array");
			Runtime.Assert(IsValidTypeAndValue<int>(v, 0, 42), "JSON Parsing failed: array invalid type or value #1");
			Runtime.Assert(IsValidTypeAndValue<int>(v, 1, -42), "JSON Parsing failed: array invalid type or value #2");
			Runtime.Assert(IsValidTypeAndValue<float>(v, 2, 1.8f), "JSON Parsing failed: array invalid type or value #3");
			Runtime.Assert(IsValidTypeAndValue<float>(v, 3, -1.8f), "JSON Parsing failed: array invalid type or value #4");
			Runtime.Assert(IsValidTypeAndValue<float>(v, 4, 1.8e5f), "JSON Parsing failed: array invalid type or value #5");
			Runtime.Assert(IsValidTypeAndValue<float>(v, 5, 1.8e-5f), "JSON Parsing failed: array invalid type or value #6");
			Runtime.Assert(IsValidTypeAndValue<int>(v, 6, 420000000), "JSON Parsing failed: array invalid type or value #7");
			Runtime.Assert(IsValidTypeAndValue<int>(v, 7, -420000000), "JSON Parsing failed: array invalid type or value #8");
			Runtime.Assert(IsValidTypeAndValue<JSON_LITERAL>(v, 8, .TRUE), "JSON Parsing failed: array invalid type or value #9");
			Runtime.Assert(IsValidTypeAndValue<JSON_LITERAL>(v, 9, .FALSE), "JSON Parsing failed: array invalid type or value #10");
			Runtime.Assert(IsValidTypeAndValue<JSON_LITERAL>(v, 10, .NULL), "JSON Parsing failed: array invalid type or value #11");
			Runtime.Assert(IsValidTypeAndValue<String>(v, 11, "a string"), "JSON Parsing failed: array invalid type or value #12");
		}

		static void ValidateObject(JSONArray array)
		{
			var obj = array.Get<JSONObject>(1);
			Runtime.Assert(IsValidType<JSONObject>(ref obj), "JSON Parsing failed: Invalid type second value in array");
			let v = obj.Get();

			Runtime.Assert(IsValidTypeAndValue<int>(v, "a int", 42), "JSON Parsing failed: object invalid type or value #1");
			Runtime.Assert(IsValidTypeAndValue<int>(v, "a negative int", -42), "JSON Parsing failed: object invalid type or value #2");
			Runtime.Assert(IsValidTypeAndValue<float>(v, "a float", 1.8f), "JSON Parsing failed: object invalid type or value #3");
			Runtime.Assert(IsValidTypeAndValue<float>(v, "a negative float", -1.8f), "JSON Parsing failed: object invalid type or value #4");
			Runtime.Assert(IsValidTypeAndValue<float>(v, "a float scientific notation number", 1.8e42f), "JSON Parsing failed: object invalid type or value #5");
			Runtime.Assert(IsValidTypeAndValue<float>(v, "a float negative scientific notation number", 1.8e-42f), "JSON Parsing failed: object invalid type or value #6");
			Runtime.Assert(IsValidTypeAndValue<int>(v, "an int scientific notation number", 420000000), "JSON Parsing failed: object invalid type or value #7");
			Runtime.Assert(IsValidTypeAndValue<int>(v, "an int negative scientific notation number", -420000000), "JSON Parsing failed: object invalid type or value #8");
			Runtime.Assert(IsValidTypeAndValue<JSON_LITERAL>(v, "true", .TRUE), "JSON Parsing failed: object invalid type or value #9");
			Runtime.Assert(IsValidTypeAndValue<JSON_LITERAL>(v, "false", .FALSE), "JSON Parsing failed: object invalid type or value #10");
			Runtime.Assert(IsValidTypeAndValue<JSON_LITERAL>(v, "null", .NULL), "JSON Parsing failed: object invalid type or value #11");
			Runtime.Assert(IsValidTypeAndValue<String>(v, "a string", "a string"), "JSON Parsing failed: object invalid type or value #12");
			Runtime.Assert(IsValidTypeAndValue<String>(v, "escaped char in string", "line 1 \n\tline 2 \r\n\tline 2"), "JSON Parsing failed: object invalid type or value #13");

			var arr = v.Get<JSONArray>("an array");
			Runtime.Assert(IsValidType<JSONArray>(ref arr), "JSON Parsing failed: object invalid type or value #14");
			ValidateArray(arr);

			var anotherObj = v.Get<JSONObject>("an object");
			Runtime.Assert(IsValidType<JSONObject>(ref anotherObj), "JSON Parsing failed: object invalid type or value #15");
			Runtime.Assert(IsValidTypeAndValue<JSON_LITERAL>(anotherObj, "hello", .TRUE), "JSON Parsing failed: object invalid type or value #16");
		}

		static void ValidateObject(JSONObject v)
		{
			Runtime.Assert(IsValidTypeAndValue<int>(v, "a int", 42), "JSON Parsing failed: object invalid type or value #1");
			Runtime.Assert(IsValidTypeAndValue<int>(v, "a negative int", -42), "JSON Parsing failed: object invalid type or value #2");
			Runtime.Assert(IsValidTypeAndValue<float>(v, "a float", 1.8f), "JSON Parsing failed: object invalid type or value #3");
			Runtime.Assert(IsValidTypeAndValue<float>(v, "a negative float", -1.8f), "JSON Parsing failed: object invalid type or value #4");
			Runtime.Assert(IsValidTypeAndValue<float>(v, "a float scientific notation number", 1.8e7f), "JSON Parsing failed: object invalid type or value #5");
			Runtime.Assert(IsValidTypeAndValue<float>(v, "a float negative scientific notation number", 1.8e-12f), "JSON Parsing failed: object invalid type or value #6");
			Runtime.Assert(IsValidTypeAndValue<int>(v, "an int scientific notation number", 420000000), "JSON Parsing failed: object invalid type or value #7");
			Runtime.Assert(IsValidTypeAndValue<int>(v, "an int negative scientific notation number", -42000), "JSON Parsing failed: object invalid type or value #8");
			Runtime.Assert(IsValidTypeAndValue<JSON_LITERAL>(v, "true", .TRUE), "JSON Parsing failed: object invalid type or value #9");
			Runtime.Assert(IsValidTypeAndValue<JSON_LITERAL>(v, "false", .FALSE), "JSON Parsing failed: object invalid type or value #10");
			Runtime.Assert(IsValidTypeAndValue<JSON_LITERAL>(v, "null", .NULL), "JSON Parsing failed: object invalid type or value #11");
			Runtime.Assert(IsValidTypeAndValue<String>(v, "a string", "a string"), "JSON Parsing failed: object invalid type or value #12");
			Runtime.Assert(IsValidTypeAndValue<String>(v, "escaped char in string", "line 1 \n\tline 2 \r\n\tline 2"), "JSON Parsing failed: object invalid type or value #13");

			var arr = v.Get<JSONArray>("an array");
			Runtime.Assert(IsValidType<JSONArray>(ref arr), "JSON Parsing failed: object invalid type or value #14");
			ValidateArray(arr);

			var anotherObj = v.Get<JSONObject>("an object");
			Runtime.Assert(IsValidType<JSONObject>(ref anotherObj), "JSON Parsing failed: object invalid type or value #15");
			Runtime.Assert(IsValidTypeAndValue<JSON_LITERAL>(anotherObj, "hello", .TRUE), "JSON Parsing failed: object invalid type or value #16");
		}

		static void ValidateArray(JSONArray v)
		{
			Runtime.Assert(v.Count == 12, "JSON Parsing failed: invalid count in array");
			Runtime.Assert(IsValidTypeAndValue<int>(v, 0, 42), "JSON Parsing failed: array invalid type or value #17");
			Runtime.Assert(IsValidTypeAndValue<int>(v, 1, -42), "JSON Parsing failed: array invalid type or value #18");
			Runtime.Assert(IsValidTypeAndValue<float>(v, 2, 1.8f), "JSON Parsing failed: array invalid type or value #19");
			Runtime.Assert(IsValidTypeAndValue<float>(v, 3, -1.8f), "JSON Parsing failed: array invalid type or value #20");
			Runtime.Assert(IsValidTypeAndValue<float>(v, 4, 1.8e5f), "JSON Parsing failed: array invalid type or value #21");
			Runtime.Assert(IsValidTypeAndValue<float>(v, 5, 1.8e-3f), "JSON Parsing failed: array invalid type or value #22");
			Runtime.Assert(IsValidTypeAndValue<int>(v, 6, 420000000), "JSON Parsing failed: array invalid type or value #23");
			Runtime.Assert(IsValidTypeAndValue<int>(v, 7, -420000000), "JSON Parsing failed: array invalid type or value #24");
			Runtime.Assert(IsValidTypeAndValue<JSON_LITERAL>(v, 8, .TRUE), "JSON Parsing failed: array invalid type or value #25");
			Runtime.Assert(IsValidTypeAndValue<JSON_LITERAL>(v, 9, .FALSE), "JSON Parsing failed: array invalid type or value #26");
			Runtime.Assert(IsValidTypeAndValue<JSON_LITERAL>(v, 10, .NULL), "JSON Parsing failed: array invalid type or value #27");
			Runtime.Assert(IsValidTypeAndValue<String>(v, 11, "a string"), "JSON Parsing failed: array invalid type or value #28");
		}

		static bool IsValidType<T>(ref Result<T, JSON_ERRORS> res)
		{
			switch (res)
			{
			case .Err(.INDEX_OUT_OF_BOUNDS), .Err(.INVALID_RETURN_TYPE):
				return false;
			default:
				return true;
			}
		}

		static bool IsValidTypeAndValue<T>(JSONArray a, int idx, T value)
		{
			var v = a.Get<T>(idx);

			var isValidType = IsValidType<T>(ref v);
			var isValidValue = (v.Get() == value);

			return (isValidType && isValidValue);
		}

		static bool IsValidTypeAndValue<T>(JSONObject o, String key, T value)
		{
			var v = o.Get<T>(key);

			var isValidType = IsValidType<T>(ref v);
			var isValidValue = (v.Get() == value);

			return (isValidType && isValidValue);
		}

		static void TestJsonSerializing()
		{
			let author = scope Author("Jonathan", "Racaud", 25);
			author.Publishers.Add("GoldenBooks");
			author.Publishers.Add("AncientBooks");
			author.Publishers.Add("NewBooks");
			author.Books.Add(new Book("The Art of War"));
			author.Books.Add(new Book("Flowers for Algernon"));
			author.Books.Add(new Book("Another book"));

			let finalStr = "{\"FirstName\":\"Jonathan\",\"LastName\":\"Racaud\",\"Books\":[{\"Name\":\"The Art of War\"},{\"Name\":\"Flowers for Algernon\"},{\"Name\":\"Another book\"}]}";

			let json = JSONSerializer.Serialize<JSONObject>(author);

			if (json != .Err)
			{
				let obj = json.Value;
				let str = scope String();

				obj.ToString(str);
				Runtime.Assert(str.Equals(finalStr), "JSON Serializing failed #1");
			}

			delete json.Value;
		}
	}
}
