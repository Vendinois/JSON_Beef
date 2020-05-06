using System;
using System.IO;
using System.Collections;
using System.Text;

namespace JSON_Beef
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

			Console.WriteLine("Press any [enter] to exit.");
			Console.In.Read();
		}

		static void TestStringsValidation()
		{
			Runtime.AssertTrue(JSONValidator.IsValidString("\"\""), "String Validation Test #1 failed");
			Runtime.AssertTrue(JSONValidator.IsValidString("\"abcdefghijklmnopqrstuvwxyz1234567890-!@#$%^&*()_+[]{};:'?.><,/\""), "String Validation Test #2 failed");
			Runtime.AssertTrue(JSONValidator.IsValidString("\"\r\n\t\f\b\u{0063}\""), "String Validation Test #3 failed");
			Runtime.AssertTrue(JSONValidator.IsValidString("\"\a\"") == false, "String Validation Test #4 failed");

			Console.WriteLine("Strings validation tests passed");
		}

		static void TestNumbersValidation()
		{
			Runtime.AssertTrue(JSONValidator.IsValidNumber("42"), "Numbers Validation Test #1 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("-42"), "Numbers Validation Test #2 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("42.42"), "Numbers Validation Test #3 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("-42.42"), "Numbers Validation Test #4 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("42e3"), "Numbers Validation Test #5 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("42e+3"), "Numbers Validation Test #6 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("42e-3"), "Numbers Validation Test #7 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("-42e3"), "Numbers Validation Test #8 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("-42e+3"), "Numbers Validation Test #9 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("-42e-3"), "Numbers Validation Test #10 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("4.2e+3"), "Numbers Validation Test #11 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("-4.2e+3"), "Numbers Validation Test #12 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("4.2e+3.3") == false, "Numbers Validation Test #13 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("4.2.3") == false, "Numbers Validation Test #14 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("4.2e-3.3") == false, "Numbers Validation Test #15 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("4.2e3.3") == false, "Numbers Validation Test #16 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("4.2+3.3") == false, "Numbers Validation Test #17 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("4.2-3.3") == false, "Numbers Validation Test #18 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("--4.2") == false, "Numbers Validation Test #19 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber(".43") == false, "Numbers Validation Test #20 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("e43") == false, "Numbers Validation Test #21 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("-e43") == false, "Numbers Validation Test #22 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("+e43") == false, "Numbers Validation Test #23 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("+") == false, "Numbers Validation Test #24 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("-") == false, "Numbers Validation Test #25 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("e43") == false, "Numbers Validation Test #26 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("\r\n\t\f\b\u{0063}") == false, "Numbers Validation Test #27 failed");
			Runtime.AssertTrue(JSONValidator.IsValidNumber("true") == false, "Numbers Validation Test #28 failed");

			Console.WriteLine("Numbers validation tests passed");
		}

		static void TestLiteralsValidation()
		{
			Runtime.AssertTrue(JSONValidator.IsValidLiteral("true"), "Literals Validation Test #1 failed");
			Runtime.AssertTrue(JSONValidator.IsValidLiteral("false"), "Literals Validation Test #2 failed");
			Runtime.AssertTrue(JSONValidator.IsValidLiteral("null"), "Literals Validation Test #3 failed");
			Runtime.AssertTrue(JSONValidator.IsValidLiteral("test") == false, "Literals Validation Test #4 failed");
			Runtime.AssertTrue(JSONValidator.IsValidLiteral("42") == false, "Literals Validation Test #5 failed");
			Runtime.AssertTrue(JSONValidator.IsValidLiteral("[]") == false, "Literals Validation Test #6 failed");
			Runtime.AssertTrue(JSONValidator.IsValidLiteral("{}") == false, "Literals Validation Test #7 failed");

			Console.WriteLine("Literals validation tests passed");
		}

		static void TestArraysValidation()
		{
			Runtime.AssertTrue(JSONValidator.IsValidArray("[]"), "Arrays Validation Test #1 failed");
			Runtime.AssertTrue(JSONValidator.IsValidArray("[42,\"toto\", true]"), "Arrays Validation Test #2 failed");
			Runtime.AssertTrue(JSONValidator.IsValidArray("[{}]"), "Arrays Validation Test #3 failed");
			Runtime.AssertTrue(JSONValidator.IsValidArray("[[]]"), "Arrays Validation Test #4 failed");
			Runtime.AssertTrue(JSONValidator.IsValidArray("[,,,,]") == false, "Arrays Validation Test #5 failed");
			Runtime.AssertTrue(JSONValidator.IsValidArray("[,]") == false, "Arrays Validation Test #6 failed");
			Runtime.AssertTrue(JSONValidator.IsValidArray("[42,]") == false, "Arrays Validation Test #7 failed");
			Runtime.AssertTrue(JSONValidator.IsValidArray("[{}") == false, "Arrays Validation Test #8 failed");
			Runtime.AssertTrue(JSONValidator.IsValidArray("[") == false, "Arrays Validation Test #9 failed");
			Runtime.AssertTrue(JSONValidator.IsValidArray("[\"t") == false, "Arrays Validation Test #10 failed");

			Console.WriteLine("Arrays validation tests passed");
		}

		static void TestObjectsValidation()
		{
			Runtime.AssertTrue(JSONValidator.IsValidObject("{}"), "Objects Validation Test #1 failed");
			Runtime.AssertTrue(JSONValidator.IsValidObject("{\"key\":\"a string value\", \"another key\": 42}"), "Objects Validation Test #2 failed");
			Runtime.AssertTrue(JSONValidator.IsValidObject("{\"key\":[], \"another key\": {}}"), "Objects Validation Test #3 failed");
			Runtime.AssertTrue(JSONValidator.IsValidObject("{\"key\":\"a string value\", \"another key\":}") == false, "Objects Validation Test #4 failed");
			Runtime.AssertTrue(JSONValidator.IsValidObject("{\"key\":\"a string value\", 'another key': 42") == false, "Objects Validation Test #5 failed");
			Runtime.AssertTrue(JSONValidator.IsValidObject("{\"key\":\"a string value\", \"another key") == false, "Objects Validation Test #6 failed");

			Console.WriteLine("Objects validation tests passed");
		}

		static void TestJsonFileValidation()
		{
			var exePath = scope String();
			Environment.GetExecutableFilePath(exePath);

			var dir = scope String();
			Path.GetDirectoryPath(exePath, dir);

			var validFile = scope String();
			Path.Join(dir, "valid.json", validFile);

			var sr = scope StreamReader();

			if (sr.Open(validFile) != .Err(.NotFound))
			{
				let data = scope String();
				sr.ReadToEnd(data);

				Runtime.AssertTrue(JSONValidator.IsValidJson(data), "Json file validation test #1 failed");
			}

			Console.WriteLine("Json file validation tests passed");
		}
	}
}
