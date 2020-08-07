using System;
using System.Collections;

namespace JSON_Beef.Util
{
	public class JSONValidator
	{
		public static bool IsValidJson(String json)
		{
			let c = json[0];
			let str = scope String(&json[0]);

			if (c == '[')
			{
				return IsValidArray(str);
			}
			else if (c == '{')
			{
				return IsValidObject(str);
			}

			return false;
		}

		public static bool IsValidString(String json)
		{
			var isValid = true;

			ValidateString(json, ref isValid);

			return isValid;
		}

		public static bool IsValidNumber(String json)
		{
			var isValid = true;

			ValidateNumber(json, ref isValid);

			return isValid;
		}

		public static bool IsValidLiteral(String json)
		{
			var isValid = true;

			ValidateLiteral(json, ref isValid);

			return isValid;
		}

		public static bool IsValidObject(String json)
		{
			var isValid = true;

			ValidateObject(json, ref isValid);

			return isValid;
		}

		public static bool IsValidArray(String json)
		{
			var isValid = true;

			ValidateArray(json, ref isValid);

			return isValid;
		}

		private static int ValidateString(String json, ref bool isValid)
		{
			int i;
			var foundEndString = false;

			List<char8> escapedChar = scope List<char8>();
			escapedChar.Add('\\');
			escapedChar.Add('\"');
			escapedChar.Add('\b');
			escapedChar.Add('\f');
			escapedChar.Add('\n');
			escapedChar.Add('\r');
			escapedChar.Add('\t');
			
			if (json[0] != '"')
			{
				isValid = false;
				return 0;
			}

			for (i = 1; i < json.Length; i++)
			{
				let c = json[i];

				if (!IsPrintable(c) && !escapedChar.Contains(c))
				{
					isValid = false;
				}
				else if (c == '"')
				{
					foundEndString = true;
				}

				if (!isValid || foundEndString)
				{
					break;
				}
			}

			isValid = foundEndString;

			return i;
		}

		private static bool IsPrintable(char8 c)
		{
			return (c >= (char8)21) && (c <= (char8)126);
		}

		private static int ValidateNumber(String json, ref bool isValid)
		{
			int i = 0;
			var dotCount = 0;
			var plusCount = 0;
			var minusCount = 0;
			var eCount = 0;
			var gotDigit = false;

			if (!json[i].IsNumber && (json[i] != '-'))
			{
				isValid = false;
				return 0;
			}
			else if (json[i].IsNumber)
			{
				gotDigit = true;
			}

			for (i = 1; i < json.Length; i++)
			{
				let c = json[i];
				let prevC = json[i - 1];

				if (!c.IsNumber)
				{
					if ((c == ',') || (c.IsWhiteSpace) || (c == ']') || (c == '}'))
					{
						break;
					}
					else if (!IsValidSymbol(c, prevC))
					{
						isValid = false;
					}

					if (((c == '.') && (dotCount >= 1)) ||
						((c == '-') && (minusCount >= 1)) ||
						((c == '+') && (plusCount >= 1)) ||
						((c == 'e') && (eCount >= 1)) ||
						((c == 'E') && (eCount >= 1)))
					{
						isValid = false;
					}

					dotCount = (c == '.') ? (dotCount + 1) : (dotCount);
					minusCount = (c == '-') ? (minusCount + 1) : (minusCount);
					plusCount = (c == '+') ? (plusCount + 1) : (plusCount);
					eCount = ((c == 'e') || (c == 'E')) ? (eCount + 1) : (eCount);
				}
				else
				{
					gotDigit = true;
				}

				if (!isValid)
				{
					break;
				}
			}

			if (!gotDigit)
			{
				isValid = false;
			}

			return i - 1;
		}

		private static bool IsValidSymbol(char8 c, char8 prevC)
		{
			var isValid = true;
			var symbols = scope List<char8>();
			symbols.Add('e');
			symbols.Add('E');
			symbols.Add('.');
			symbols.Add('+');
			symbols.Add('-');

			if (!symbols.Contains(c))
			{
				isValid = false;
			}
			else
			{
				if (((c == 'e') || (c == 'E') || (c == '.')) && (!prevC.IsNumber))
				{
					isValid = false;
				}
				else if (((c == '+') || (c == '-')) && ((prevC != 'e') && (prevC != 'E')))
				{
					isValid = false;
				}
			}

			return isValid;
		}

		private static int ValidateLiteral(String json, ref bool isValid)
		{
			int i = 0;
			var str = scope String();

			isValid = false;

			for (i = 0; i < json.Length; i++)
			{
				let c = json[i];

				if (!c.IsLetter)
				{
					break;
				}

				str.Append(c);
			}

			if (str.Equals("true") || (str.Equals("false") || str.Equals("null")))
			{
				isValid = true;
			}

			return i - 1;
		}

		private static int ValidateObject(String json, ref bool isValid)
		{
			int i;
			var lookForKey = true;
			var lookForValueSeparator = false;
			var lookForKeySeparator = false;
			var lookForValue = false;
			var keyCount = 0;
			var valueCount = 0;

			if (json[0] != '{')
			{
				isValid = false;
				return 0;
			}	

			for (i = 1; i < json.Length; i++)
			{
				let c = json[i];

				if (!c.IsWhiteSpace)
				{
					if (c == '}')
					{
						break;
					}

					if ((c != '"') && lookForKey)
					{
						isValid = false;
					}

					if ((c != ':') && lookForKeySeparator)
					{
						isValid = false;
					}
					else if ((c == ':') && lookForKeySeparator)
					{
						lookForKeySeparator = false;
						lookForValue = true;
					}

					if ((c != ',') && (c != '}') && lookForValueSeparator)
					{
						isValid = false;
					}
					else if ((c == ',') && lookForValueSeparator)
					{
						lookForValueSeparator = false;
						lookForKey = true;
					}

					if (c == '"')
					{
						let str = scope String(&json[i]);
						i += ValidateString(str, ref isValid);

						if (lookForKey)
						{
							lookForKey = false;
							lookForKeySeparator = true;
							keyCount++;
						}
						else
						{
							lookForValueSeparator = true;
							lookForValue = false;
							valueCount++;
						}
					}
					else if (c.IsLetter && lookForValue)
					{
						let str = scope String(&json[i]);
						i += ValidateLiteral(str, ref isValid);
						lookForValueSeparator = true;
						lookForValue = false;
						valueCount++;
					}
					else if ((c.IsNumber || (c == '-')) && lookForValue)
					{
						let str = scope String(&json[i]);
						i += ValidateNumber(str, ref isValid);
						lookForValueSeparator = true;
						lookForValue = false;
						valueCount++;
					}
					else if ((c == '[') && lookForValue)
					{
						let str = scope String(&json[i]);
						i += ValidateArray(str, ref isValid);
						lookForValueSeparator = true;
						lookForValue = false;
						valueCount++;
					}
					else if ((c == '{') && lookForValue)
					{
						let str = scope String(&json[i]);
						i += ValidateObject(str, ref isValid);
						lookForValueSeparator = true;
						lookForValue = false;
						valueCount++;
					}
				}

				if (!isValid)
				{
					break;
				}
			}

			isValid = (isValid) ? (keyCount == valueCount) : (false);

			return i;
		}

		private static int ValidateArray(String json, ref bool isValid)
		{
			int i;
			var foundEndArray = false;
			var lookForValueSeparator = false;
			var lastChar = ' ';

			if (json[0] != '[')
			{
				isValid = false;
				return 0;
			}

			for (i = 1; i < json.Length; i++)
			{
				let c = json[i];

				if (c == '[')
				{
					let str = scope String(&json[i]);
					i += ValidateArray(str, ref isValid);
					lookForValueSeparator = true;
					lastChar = ' ';
				}
				else if ((c == ']') && (lastChar != ','))
				{
					foundEndArray = true;
				}
				else if ((c == ']') && (lastChar == ','))
				{
					isValid = false;
				}
				else if (c == '{')
				{
					let str = scope String(&json[i]);
					i += ValidateObject(str, ref isValid);
					lookForValueSeparator = true;
					lastChar = ' ';
				}
				else if (c.IsNumber || (c == '-'))
				{
					let str = scope String(&json[i]);
					i += ValidateNumber(str, ref isValid);
					lookForValueSeparator = true;
					lastChar = ' ';
				}
				else if (c.IsLetter)
				{
					let str = scope String(&json[i]);
					i += ValidateLiteral(str, ref isValid);
					lookForValueSeparator = true;
					lastChar = ' ';
				}
				else if (c == '"')
				{
					let str = scope String(&json[i]);
					i += ValidateString(str, ref isValid);
					lookForValueSeparator = true;
					lastChar = ' ';
				}
				else if ((c != ',') && (!c.IsWhiteSpace) && lookForValueSeparator && !foundEndArray)
				{
					isValid = false;
				}
				else if ((c == ',') && lookForValueSeparator)
				{
					lookForValueSeparator = false;
					lastChar = ',';
				}
				else if ((c == ',') && !lookForValueSeparator)
				{
					isValid = false;
				}

				if (!isValid || foundEndArray)
				{
					return i;
				}
			}

			isValid = foundEndArray;
			return i;
		}
	}
}
