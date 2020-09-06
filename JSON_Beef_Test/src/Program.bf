using System;
using System.Collections;
using System.IO;
using JSON_Beef.Serialization;
using JSON_Beef.Util;
using JSON_Beef.Types;

namespace JSON_Beef_Test
{
	// Todo:
	// Fix memory leaks from JSONDeserializer and this program class.
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
			TestJsonDeserializing();
			TestStruct();

			Console.WriteLine("Press [enter] to exit.");
			Console.In.Read();
		}

		[Test]
		static void TestStringsValidation()
		{
			Test.Assert(JSONValidator.IsValidString("\"\""), "String Validation Test #1 failed");
			Test.Assert(JSONValidator.IsValidString("\"abcdefghijklmnopqrstuvwxyz1234567890-!@#$%^&*()_+[]{};:'?.><,/\""), "String Validation Test #2 failed");
			Test.Assert(JSONValidator.IsValidString("\"\r\n\t\f\b\u{0063}\""), "String Validation Test #3 failed");
			Test.Assert(JSONValidator.IsValidString("\"\a\"") == false, "String Validation Test #4 failed");

			Console.WriteLine("Strings validation tests passed");
		}

		[Test]
		static void TestNumbersValidation()
		{
			Test.Assert(JSONValidator.IsValidNumber("42"), "Numbers Validation Test #1 failed");
			Test.Assert(JSONValidator.IsValidNumber("-42"), "Numbers Validation Test #2 failed");
			Test.Assert(JSONValidator.IsValidNumber("4242"), "Numbers Validation Test #3 failed");
			Test.Assert(JSONValidator.IsValidNumber("-42.42"), "Numbers Validation Test #4 failed");
			Test.Assert(JSONValidator.IsValidNumber("42e3"), "Numbers Validation Test #5 failed");
			Test.Assert(JSONValidator.IsValidNumber("42e+3"), "Numbers Validation Test #6 failed");
			Test.Assert(JSONValidator.IsValidNumber("42e-3"), "Numbers Validation Test #7 failed");
			Test.Assert(JSONValidator.IsValidNumber("-42e3"), "Numbers Validation Test #8 failed");
			Test.Assert(JSONValidator.IsValidNumber("-42e+3"), "Numbers Validation Test #9 failed");
			Test.Assert(JSONValidator.IsValidNumber("-42e-3"), "Numbers Validation Test #10 failed");
			Test.Assert(JSONValidator.IsValidNumber("4.2e+3"), "Numbers Validation Test #11 failed");
			Test.Assert(JSONValidator.IsValidNumber("-4.2e+3"), "Numbers Validation Test #12 failed");
			Test.Assert(JSONValidator.IsValidNumber("4.2e+3.3") == false, "Numbers Validation Test #13 failed");
			Test.Assert(JSONValidator.IsValidNumber("4.2.3") == false, "Numbers Validation Test #14 failed");
			Test.Assert(JSONValidator.IsValidNumber("4.2e-3.3") == false, "Numbers Validation Test #15 failed");
			Test.Assert(JSONValidator.IsValidNumber("4.2e3.3") == false, "Numbers Validation Test #16 failed");
			Test.Assert(JSONValidator.IsValidNumber("4.2+3.3") == false, "Numbers Validation Test #17 failed");
			Test.Assert(JSONValidator.IsValidNumber("4.2-3.3") == false, "Numbers Validation Test #18 failed");
			Test.Assert(JSONValidator.IsValidNumber("--4.2") == false, "Numbers Validation Test #19 failed");
			Test.Assert(JSONValidator.IsValidNumber(".43") == false, "Numbers Validation Test #20 failed");
			Test.Assert(JSONValidator.IsValidNumber("e43") == false, "Numbers Validation Test #21 failed");
			Test.Assert(JSONValidator.IsValidNumber("-e43") == false, "Numbers Validation Test #22 failed");
			Test.Assert(JSONValidator.IsValidNumber("+e43") == false, "Numbers Validation Test #23 failed");
			Test.Assert(JSONValidator.IsValidNumber("+") == false, "Numbers Validation Test #24 failed");
			Test.Assert(JSONValidator.IsValidNumber("-") == false, "Numbers Validation Test #25 failed");
			Test.Assert(JSONValidator.IsValidNumber("e43") == false, "Numbers Validation Test #26 failed");
			Test.Assert(JSONValidator.IsValidNumber("\r\n\t\f\b\u{0063}") == false, "Numbers Validation Test #27 failed");
			Test.Assert(JSONValidator.IsValidNumber("true") == false, "Numbers Validation Test #28 failed");

			Console.WriteLine("Numbers validation tests passed");
		}

		[Test]
		static void TestLiteralsValidation()
		{
			Test.Assert(JSONValidator.IsValidLiteral("true"), "Literals Validation Test #1 failed");
			Test.Assert(JSONValidator.IsValidLiteral("false"), "Literals Validation Test #2 failed");
			Test.Assert(JSONValidator.IsValidLiteral("null"), "Literals Validation Test #3 failed");
			Test.Assert(JSONValidator.IsValidLiteral("test") == false, "Literals Validation Test #4 failed");
			Test.Assert(JSONValidator.IsValidLiteral("42") == false, "Literals Validation Test #5 failed");
			Test.Assert(JSONValidator.IsValidLiteral("[]") == false, "Literals Validation Test #6 failed");
			Test.Assert(JSONValidator.IsValidLiteral("{}") == false, "Literals Validation Test #7 failed");

			Console.WriteLine("Literals validation tests passed");
		}

		[Test]
		static void TestArraysValidation()
		{
			Test.Assert(JSONValidator.IsValidArray("[]"), "Arrays Validation Test #1 failed");
			Test.Assert(JSONValidator.IsValidArray("[42,\"toto\", true]"), "Arrays Validation Test #2 failed");
			Test.Assert(JSONValidator.IsValidArray("[{}]"), "Arrays Validation Test #3 failed");
			Test.Assert(JSONValidator.IsValidArray("[[]]"), "Arrays Validation Test #4 failed");
			Test.Assert(JSONValidator.IsValidArray("[,,,,]") == false, "Arrays Validation Test #5 failed");
			Test.Assert(JSONValidator.IsValidArray("[,]") == false, "Arrays Validation Test #6 failed");
			Test.Assert(JSONValidator.IsValidArray("[42,]") == false, "Arrays Validation Test #7 failed");
			Test.Assert(JSONValidator.IsValidArray("[{}") == false, "Arrays Validation Test #8 failed");
			Test.Assert(JSONValidator.IsValidArray("[") == false, "Arrays Validation Test #9 failed");
			Test.Assert(JSONValidator.IsValidArray("[\"t") == false, "Arrays Validation Test #10 failed");

			Console.WriteLine("Arrays validation tests passed");
		}

		[Test]
		static void TestObjectsValidation()
		{
			Test.Assert(JSONValidator.IsValidObject("{}"), "Objects Validation Test #1 failed");
			Test.Assert(JSONValidator.IsValidObject("{\"key\":\"a string value\", \"another key\": 42}"), "Objects Validation Test #2 failed");
			Test.Assert(JSONValidator.IsValidObject("{\"key\":[], \"another key\": {}}"), "Objects Validation Test #3 failed");
			Test.Assert(JSONValidator.IsValidObject("{\"key\":\"a string value\", \"another key\":}") == false, "Objects Validation Test #4 failed");
			Test.Assert(JSONValidator.IsValidObject("{\"key\":\"a string value\", 'another key': 42") == false, "Objects Validation Test #5 failed");
			Test.Assert(JSONValidator.IsValidObject("{\"key\":\"a string value\", \"another key") == false, "Objects Validation Test #6 failed");

			Console.WriteLine("Objects validation tests passed");
		}

		[Test]
		static void TestJsonFileValidation()
		{
			var data = scope String();
			var gotData = GetValidArrayData(data);

			if (gotData)
			{
				Test.Assert(JSONValidator.IsValidJson(data), "Json file validation test #1 failed");
			}
			else
			{
				Test.Assert(false, "Failed loading array data");
			}

			gotData = GetValidObjectData(data);
			if (gotData)
			{
				Test.Assert(JSONValidator.IsValidJson(data), "Json file validation test #2 failed");
			}
			else
			{
				Test.Assert(false, "Failed loading object data");
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

		[Test]
		static void TestJsonUtil()
		{
			Test.Assert(JSONUtil.ParseNumber<uint>("42") == (uint)42, "JSONUtil test #1 failed");
			Test.Assert(JSONUtil.ParseNumber<uint64>("42e5") == (uint64)4200000, "JSONUtil test #2 failed");
			Test.Assert(JSONUtil.ParseNumber<int>("-42e3") == -42000, "JSONUtil test #3 failed");

			var res = JSONUtil.ParseNumber<int>("4.2");
			Test.Assert(ValidError(ref res), "JSONUtil test #4 failed");

			res = JSONUtil.ParseNumber<int>("42e-3");
			Test.Assert(ValidError(ref res), "JSONUtil test #5 failed");

			Test.Assert(JSONUtil.ParseNumber<float>("42").Value.Equals(42f), "JSONUtil test #6 failed");
			Test.Assert(JSONUtil.ParseNumber<float>("-42").Value.Equals(-42f), "JSONUtil test #7 failed");
			Test.Assert(JSONUtil.ParseNumber<float>("4.2").Value.Equals(4.2f), "JSONUtil test #8 failed");
			Test.Assert(JSONUtil.ParseNumber<float>("-4.2").Value.Equals(-4.2f), "JSONUtil test #9 failed");
			Test.Assert(JSONUtil.ParseNumber<float>("42e3").Value.Equals(42000f), "JSONUtil test #10 failed");
			Test.Assert(JSONUtil.ParseNumber<float>("-42e3").Value.Equals(-42000f), "JSONUtil test #11 failed");
			Test.Assert(JSONUtil.ParseNumber<float>("4.2e3").Value.Equals(4200f), "JSONUtil test #12 failed");
			Test.Assert(JSONUtil.ParseNumber<float>("-4.2e3").Value.Equals(-4200f), "JSONUtil test #13 failed");
			Test.Assert(JSONUtil.ParseNumber<float>("4.2e-3").Value.Equals(0.0042f), "JSONUtil test #14 failed");
			Test.Assert(JSONUtil.ParseNumber<float>("-4.2e-3").Value.Equals(-0.0042f), "JSONUtil test #15 failed");

			Test.Assert(JSONUtil.ParseNumber<double>("42").Value.Equals(42), "JSONUtil test #6 failed");
			Test.Assert(JSONUtil.ParseNumber<double>("-42").Value.Equals(-42), "JSONUtil test #7 failed");
			Test.Assert(JSONUtil.ParseNumber<double>("4.2").Value.Equals(4.2), "JSONUtil test #8 failed");
			Test.Assert(JSONUtil.ParseNumber<double>("-4.2").Value.Equals(-4.2), "JSONUtil test #9 failed");
			Test.Assert(JSONUtil.ParseNumber<double>("42e3").Value.Equals(42000), "JSONUtil test #10 failed");
			Test.Assert(JSONUtil.ParseNumber<double>("-42e3").Value.Equals(-42000), "JSONUtil test #11 failed");
			Test.Assert(JSONUtil.ParseNumber<double>("4.2e3").Value.Equals(4200), "JSONUtil test #12 failed");
			Test.Assert(JSONUtil.ParseNumber<double>("-4.2e3").Value.Equals(-4200), "JSONUtil test #13 failed");
			Test.Assert(JSONUtil.ParseNumber<double>("4.2e-3").Value.Equals(0.0042), "JSONUtil test #14 failed");
			Test.Assert(JSONUtil.ParseNumber<double>("-4.2e-3").Value.Equals(-0.0042), "JSONUtil test #15 failed");

			Test.Assert(JSONUtil.ParseBool("true") == true, "JSONUtil test #16 failed");
			Test.Assert(JSONUtil.ParseBool("false") == false, "JSONUtil test #16 failed");
			Test.Assert(JSONUtil.ParseBool("null") == .Err(.INVALID_LITERAL_VALUE), "JSONUtil test #16 failed");

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
			var v = scope JSONArray();
			var res = array.Get<JSONArray>(0, ref v);
			Test.Assert(IsValidType<JSONArray>(ref res), "JSON Parsing failed: Invalid type first value in array");

			Test.Assert(v.Count == 12, "JSON Parsing failed: invalid count in first array");
			Test.Assert(IsValidTypeAndValue<int>(v, 0, 42), "JSON Parsing failed: array invalid type or value #1");
			Test.Assert(IsValidTypeAndValue<int>(v, 1, -42), "JSON Parsing failed: array invalid type or value #2");
			Test.Assert(IsValidTypeAndValue<float>(v, 2, 1.8f), "JSON Parsing failed: array invalid type or value #3");
			Test.Assert(IsValidTypeAndValue<float>(v, 3, -1.8f), "JSON Parsing failed: array invalid type or value #4");
			Test.Assert(IsValidTypeAndValue<float>(v, 4, 1.8e5f), "JSON Parsing failed: array invalid type or value #5");
			Test.Assert(IsValidTypeAndValue<float>(v, 5, 1.8e-5f), "JSON Parsing failed: array invalid type or value #6");
			Test.Assert(IsValidTypeAndValue<int>(v, 6, 420000000), "JSON Parsing failed: array invalid type or value #7");
			Test.Assert(IsValidTypeAndValue<int>(v, 7, -420000000), "JSON Parsing failed: array invalid type or value #8");
			Test.Assert(IsValidTypeAndValue<bool>(v, 8, true), "JSON Parsing failed: array invalid type or value #9");
			Test.Assert(IsValidTypeAndValue<bool>(v, 9, false), "JSON Parsing failed: array invalid type or value #10");
			Test.Assert(IsValidTypeAndValue<Object>(v, 10, null), "JSON Parsing failed: array invalid type or value #11");
			Test.Assert(IsValidTypeAndValue<String>(v, 11, "a string"), "JSON Parsing failed: array invalid type or value #12");
		}

		static void ValidateObject(JSONArray array)
		{
			var v = scope JSONObject();
			var res = array.Get<JSONObject>(1, ref v);
			Test.Assert(IsValidType<JSONObject>(ref res), "JSON Parsing failed: Invalid type second value in array");

			Test.Assert(IsValidTypeAndValue<int>(v, "a int", 42), "JSON Parsing failed: object invalid type or value #1");
			Test.Assert(IsValidTypeAndValue<int>(v, "a negative int", -42), "JSON Parsing failed: object invalid type or value #2");
			Test.Assert(IsValidTypeAndValue<float>(v, "a float", 1.8f), "JSON Parsing failed: object invalid type or value #3");
			Test.Assert(IsValidTypeAndValue<float>(v, "a negative float", -1.8f), "JSON Parsing failed: object invalid type or value #4");
			Test.Assert(IsValidTypeAndValue<float>(v, "a float scientific notation number", 1.8e42f), "JSON Parsing failed: object invalid type or value #5");
			Test.Assert(IsValidTypeAndValue<float>(v, "a float negative scientific notation number", 1.8e-42f), "JSON Parsing failed: object invalid type or value #6");
			Test.Assert(IsValidTypeAndValue<int>(v, "an int scientific notation number", 420000000), "JSON Parsing failed: object invalid type or value #7");
			Test.Assert(IsValidTypeAndValue<int>(v, "an int negative scientific notation number", -420000000), "JSON Parsing failed: object invalid type or value #8");
			Test.Assert(IsValidTypeAndValue<bool>(v, "true", true), "JSON Parsing failed: object invalid type or value #9");
			Test.Assert(IsValidTypeAndValue<bool>(v, "false", false), "JSON Parsing failed: object invalid type or value #10");
			Test.Assert(IsValidTypeAndValue<Object>(v, "null", null), "JSON Parsing failed: object invalid type or value #11");
			Test.Assert(IsValidTypeAndValue<String>(v, "a string", "a string"), "JSON Parsing failed: object invalid type or value #12");
			Test.Assert(IsValidTypeAndValue<String>(v, "escaped char in string", "line 1 \n\tline 2 \r\n\tline 2"), "JSON Parsing failed: object invalid type or value #13");

			var arr = scope JSONArray();
			res = v.Get<JSONArray>("an array", ref arr);
			Test.Assert(IsValidType<JSONArray>(ref res), "JSON Parsing failed: object invalid type or value #14");
			ValidateArray(arr);

			var obj = scope JSONObject();
			res = v.Get<JSONObject>("an object", ref obj);
			Test.Assert(IsValidType<JSONObject>(ref res), "JSON Parsing failed: object invalid type or value #15");
			Test.Assert(IsValidTypeAndValue<bool>(obj, "hello", true), "JSON Parsing failed: object invalid type or value #16");
		}

		static void ValidateObject(JSONObject v)
		{
			Test.Assert(IsValidTypeAndValue<int>(v, "a int", 42), "JSON Parsing failed: object invalid type or value #1");
			Test.Assert(IsValidTypeAndValue<int>(v, "a negative int", -42), "JSON Parsing failed: object invalid type or value #2");
			Test.Assert(IsValidTypeAndValue<float>(v, "a float", 1.8f), "JSON Parsing failed: object invalid type or value #3");
			Test.Assert(IsValidTypeAndValue<float>(v, "a negative float", -1.8f), "JSON Parsing failed: object invalid type or value #4");
			Test.Assert(IsValidTypeAndValue<float>(v, "a float scientific notation number", 1.8e7f), "JSON Parsing failed: object invalid type or value #5");
			Test.Assert(IsValidTypeAndValue<float>(v, "a float negative scientific notation number", 1.8e-12f), "JSON Parsing failed: object invalid type or value #6");
			Test.Assert(IsValidTypeAndValue<int>(v, "an int scientific notation number", 420000000), "JSON Parsing failed: object invalid type or value #7");
			Test.Assert(IsValidTypeAndValue<int>(v, "an int negative scientific notation number", -42000), "JSON Parsing failed: object invalid type or value #8");
			Test.Assert(IsValidTypeAndValue<bool>(v, "true", true), "JSON Parsing failed: object invalid type or value #9");
			Test.Assert(IsValidTypeAndValue<bool>(v, "false", false), "JSON Parsing failed: object invalid type or value #10");
			Test.Assert(IsValidTypeAndValue<File>(v, "null", null), "JSON Parsing failed: object invalid type or value #11");
			Test.Assert(IsValidTypeAndValue<String>(v, "a string", "a string"), "JSON Parsing failed: object invalid type or value #12");
			Test.Assert(IsValidTypeAndValue<String>(v, "escaped char in string", "line 1 \n\tline 2 \r\n\tline 2"), "JSON Parsing failed: object invalid type or value #13");

			var arr = scope JSONArray();
			var res = v.Get<JSONArray>("an array", ref arr);
			Test.Assert(IsValidType<JSONArray>(ref res), "JSON Parsing failed: object invalid type or value #14");
			ValidateArray(arr);

			var obj = scope JSONObject();
			res = v.Get<JSONObject>("an object", ref obj);
			Test.Assert(IsValidType<JSONObject>(ref res), "JSON Parsing failed: object invalid type or value #15");
			Test.Assert(IsValidTypeAndValue<bool>(obj, "hello", true), "JSON Parsing failed: object invalid type or value #16");
		}

		static void ValidateArray(JSONArray v)
		{
			Test.Assert(v.Count == 12, "JSON Parsing failed: invalid count in array");
			Test.Assert(IsValidTypeAndValue<int>(v, 0, 42), "JSON Parsing failed: array invalid type or value #17");
			Test.Assert(IsValidTypeAndValue<int>(v, 1, -42), "JSON Parsing failed: array invalid type or value #18");
			Test.Assert(IsValidTypeAndValue<float>(v, 2, 1.8f), "JSON Parsing failed: array invalid type or value #19");
			Test.Assert(IsValidTypeAndValue<float>(v, 3, -1.8f), "JSON Parsing failed: array invalid type or value #20");
			Test.Assert(IsValidTypeAndValue<float>(v, 4, 1.8e5f), "JSON Parsing failed: array invalid type or value #21");
			Test.Assert(IsValidTypeAndValue<float>(v, 5, 1.8e-3f), "JSON Parsing failed: array invalid type or value #22");
			Test.Assert(IsValidTypeAndValue<int>(v, 6, 420000000), "JSON Parsing failed: array invalid type or value #23");
			Test.Assert(IsValidTypeAndValue<int>(v, 7, -420000000), "JSON Parsing failed: array invalid type or value #24");
			Test.Assert(IsValidTypeAndValue<bool>(v, 8, true), "JSON Parsing failed: array invalid type or value #25");
			Test.Assert(IsValidTypeAndValue<bool>(v, 9, false), "JSON Parsing failed: array invalid type or value #26");
			Test.Assert(IsValidTypeAndValue<Author>(v, 10, null), "JSON Parsing failed: array invalid type or value #27");
			Test.Assert(IsValidTypeAndValue<String>(v, 11, "a string"), "JSON Parsing failed: array invalid type or value #28");
		}

		static bool IsValidType<T>(ref Result<void, JSON_ERRORS> res)
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
			T v = default;
			var res = a.Get<T>(idx, ref v);

			var isValidType = IsValidType<T>(ref res);
			var isValidValue = (v == value);

			return (isValidType && isValidValue);
		}

		static bool IsValidTypeAndValue<T>(JSONObject o, String key, T value)
		{
			T v = default;
			var res = o.Get<T>(key, ref v);

			var isValidType = IsValidType<T>(ref res);
			var isValidValue = (v == value);

			return (isValidType && isValidValue);
		}

		[Test]
		static void TestJsonSerializing()
		{
			let author = scope Author("Jonathan", "Racaud", 25);
			author.Id = 1;
			author.Test = 25.4f;
			Author.Known = true;
			author.Publishers.Add(new String("GoldenBooks"));
			author.Publishers.Add(new String("AncientBooks"));
			author.Publishers.Add(new String("NewBooks"));
			author.Books.Add(new Book("The Art of War"));
			author.Books.Add(new Book("Flowers for Algernon"));
			author.Books.Add(new Book("Another book"));

			let resObj = JSONSerializer.Serialize<JSONObject>(author);

			if (resObj != .Err)
			{
				let json = resObj.Value;
				let str = scope String();

				json.ToString(str);

				let deserializedAuthor = scope Author();
				let res = JSONDeserializer.Deserialize<Author>(str, deserializedAuthor);

				switch (res)
				{
				case .Err(let err):
					Test.Assert(false, "JSON Serializing failed #1");
				case .Ok(let val):
					Test.Assert(ObjectsMatch(author, deserializedAuthor), "JSON Serializing failed #2");
				}

				delete json;
			}

			var car = Car();
			car.Age = 25;
			car.Speed = 160.0f;
			car.Name = scope String("Aston Martin");
			car.Sellers = null;

			let resStruct = JSONSerializer.Serialize<JSONObject>(car);

			if (resStruct != .Err)
			{
				let json = resStruct.Value;
				let str = scope String();

				json.ToString(str);


				var deserializedCar = Car();
				let res = JSONDeserializer.Deserialize<Car>(str, ref deserializedCar);

				switch (res)
				{
				case .Err(let err):
					Test.Assert(false, "JSON Serializing failed #3");
				case .Ok(let val):
					Test.Assert(CarsMatch(car, deserializedCar), "JSON Serializing failed #4");
				}

				delete json;
				delete deserializedCar.Name;

				if (deserializedCar.Sellers != null)
				{
					delete deserializedCar.Sellers;
				}
			}

			Console.WriteLine("JSONSerializing tests passed");
		}

		[Test]
		static void TestJsonDeserializing()
		{
			let json = "{\"Id\": 256, \"Test\": 4.2, \"Known\": true, \"FirstBook\": {\"Name\": \"Book\"}, \"FirstName\":\"Jonathan\",\"LastName\":\"Racaud\",\"Books\":[{\"Name\":\"The Art of War\"},{\"Name\":\"Flowers for Algernon\"},{\"Name\":\"Another book\"}],\"Publishers\":[\"GoldenBooks\",\"AncientBooks\",\"NewBooks\"]}";
			let author = scope Author("Jonathan", "Racaud", 25);
			author.Id = 256;
			author.Test = 4.2f;
			Author.Known = true;
			author.Publishers.Add(new String("GoldenBooks"));
			author.Publishers.Add(new String("AncientBooks"));
			author.Publishers.Add(new String("NewBooks"));
			author.Books.Add(new Book("The Art of War"));
			author.Books.Add(new Book("Flowers for Algernon"));
			author.Books.Add(new Book("Another book"));

			let deserializedAuthor = scope Author();
			var res = JSONDeserializer.Deserialize<Author>(json, deserializedAuthor);

			switch (res)
			{
			case .Err(let err):
				Test.Assert(false, "JSON Deserializing failed #1");
			case .Ok:
				Test.Assert(ObjectsMatch(author, deserializedAuthor), "JSON Deserializing failed #1");
			}

			let deserializedTest = scope TestClass();
			let jsonTest = "{\"MultipleList\": [[\"1\", \"2\"], [\"3\", \"4\"], [\"5\", \"6\"]]}";
			res = JSONDeserializer.Deserialize<TestClass>(jsonTest, deserializedTest);

			switch (res)
			{
			case .Err(let err):
				Test.Assert(false, "JSON Deserializing failed #2");
			case .Ok:
				Test.Assert(deserializedTest.MultipleList.Count == 3, "JSON Deserializing failed #2");
			}

			Console.WriteLine("JSONDeserializing tests passed");
		}

		static bool ObjectsMatch(Author a, Author b)
		{
			if ((a.FirstName != b.FirstName) ||
				((a.LastName != b.LastName)) ||
				(a.Publishers.Count != b.Publishers.Count) ||
				(a.Books.Count != b.Books.Count) ||
				(!a.FirstBook.Name.Equals(b.FirstBook.Name)) ||
				(a.Id != b.Id) ||
				!a.Test.Equals(b.Test) ||
				(Author.Known != true)
				)
			{
				return false;
			}

			var missingBooks = a.Books.Count;
			for (int i = 0; i < a.Books.Count; i++)
			{
				for (int j = 0; j < b.Books.Count; j++)
				{
					if (b.Books[j] == a.Books[i])
					{
						missingBooks--;
						break;
					}
				}
			}

			var missingPublishers = a.Publishers.Count;
			for (int i = 0; i < a.Publishers.Count; i++)
			{
				for (int j = 0; j < b.Publishers.Count; j++)
				{
					if (b.Publishers[j] == a.Publishers[i])
					{
						missingPublishers--;
						break;
					}
				}
			}

			return ((missingBooks == 0) && (missingPublishers == 0));
		}

		[Test]
		static void TestStruct()
		{
			var car = Car();
			car.Age = 25;
			car.Name = "DB9";
			car.Sellers = new List<String>();
			car.Sellers.Add(new String("Aston Martin"));

			let resObj = JSONSerializer.Serialize<JSONObject>(car);

			if (resObj != .Err)
			{
				let json = resObj.Value;
				let str = scope String();

				json.ToString(str);

				var deserializedCar = Car();
				let res = JSONDeserializer.Deserialize<Car>(str, ref deserializedCar);

				switch (res)
				{
				case .Err(let err):
					Test.Assert(false, "JSON Struct Test failed #1");
				case .Ok(let val):
					Test.Assert(CarsMatch(car, deserializedCar), "JSON Struct Test failed #2");
				}

				DeleteContainerAndItems!(car.Sellers);

				DeleteContainerAndItems!(deserializedCar.Sellers);
				delete deserializedCar.Name;
				delete json;
			}

			Console.WriteLine("JSON Struct tests passed");
		}

		static bool CarsMatch(Car a, Car b)
		{
			if ((a.Age != b.Age) ||
				(!a.Name.Equals(b.Name)) ||
				(!a.Speed.Equals(b.Speed)))
			{
				return false;
			}

			if ((a.Sellers == null) && (b.Sellers == null))
			{
				return true;
			}

			var missingSellers = a.Sellers.Count;

			for (var i = 0; i < a.Sellers.Count; i++)
			{
				for (var j = 0; j < b.Sellers.Count; j++)
				{
					if (a.Sellers[i] == b.Sellers[j])
					{
						missingSellers--;
						break;
					}
				}
			}

			return (missingSellers == 0);
		}
	}
}
