using System;
using JSON_Beef.Types;

namespace JSON_Beef.Util
{
	public class JSONUtil
	{
		public static Result<T, JSON_ERRORS> ParseNumber<T>(String json)
		{
			if (!JSONValidator.IsValidNumber(json))
			{
				return .Err(.INVALID_JSON_STRING);
			}

			let type = typeof(T);

			if (!type.IsPrimitive)
			{
				return .Err(.INVALID_RETURN_TYPE);
			}

			if (type.IsFloatingPoint)
			{
				return ParseFloatInternal<T>(json);
			}

			return ParseIntInternal<T>(json);
		}

		public static Result<bool, JSON_ERRORS> ParseBool(String json)
		{
			if (!JSONValidator.IsValidLiteral(json))
			{
				return .Err(.INVALID_JSON_STRING);
			}

			if (json.Equals("true"))
			{
				return .Ok(true);
			}
			else if (json.Equals("false"))
			{
				return .Ok(false);
			}
			else
			{
				return .Err(.INVALID_LITERAL_VALUE);
			}
		}

		[Obsolete("ParseFloat is deprecated. Use ParseNumber<float> instead.", false)]
		public static Result<float, JSON_ERRORS> ParseFloat(String json)
		{
			return ParseFloatInternal<float>(json);
		}

		[Obsolete("ParseFloat is deprecated. Use ParseNumber<float> instead.", false)]
		public static Result<int, JSON_ERRORS> ParseInt(String json)
		{
			return ParseIntInternal<int>(json);
		}

		private static Result<T, JSON_ERRORS> ParseIntInternal<T>(StringView json)
		{
			let idx = json.IndexOf('e');
			var expStartIdx = idx + 1;

			if (json.Contains('.'))
			{
				return .Err(.INVALID_NUMBER_REPRESENTATION);
			}

			if (idx == -1)
			{
				return CastToRightInt<T>(json);
			}

			if ((json[idx + 1] == '-'))
			{
				return .Err(.INVALID_NUMBER_REPRESENTATION);
			}
			else if (json[idx + 1] == '+')
			{
				expStartIdx++;
			}

			let numStr = scope String(json, 0, idx);
			let expStr = StringView(json, expStartIdx, json.Length - expStartIdx);

			var exp = Int.Parse(expStr).Get();

			for (var i = 0; i < exp; i++)
			{
				numStr.Append('0');
			}

			return CastToRightInt<T>(numStr);
		}

		private static Result<T, JSON_ERRORS> CastToRightInt<T>(StringView str)
		{
			let type = typeof(T);
			T outNum = default;

			switch (type)
			{
			// Didn't find another way to cast when using reflection.
			// Also, int8 and int16 do not provide a Parse method.
			case typeof(int), typeof(int8), typeof(int16):
				var num = int.Parse(str);
				Internal.MemCpy(&outNum, &num, type.Size);
			case typeof(int32):
				var num = int32.Parse(str);
				Internal.MemCpy(&outNum, &num, type.Size);
			case typeof(int64):
				var num = int64.Parse(str);
				Internal.MemCpy(&outNum, &num, type.Size);

			// uint8/16 and char types do not provide a Parse method.
			case typeof(uint), typeof(uint8), typeof(uint16), typeof(char8), typeof(char16), typeof(char32):
				var num = uint.Parse(str);
				Internal.MemCpy(&outNum, &num, type.Size);
			case typeof(uint32):
				var num = uint32.Parse(str);
				Internal.MemCpy(&outNum, &num, type.Size);
			case typeof(uint64):
				var num = uint64.Parse(str);
				Internal.MemCpy(&outNum, &num, type.Size);
			default:
				return .Err(.INVALID_TYPE);
			}

			return .Ok(outNum);
		}

		private static Result<T, JSON_ERRORS> ParseFloatInternal<T>(StringView json)
		{
			var str = scope String(json);
			let isNeg = (str[0] == '-');

			if (isNeg)
			{
				str.Remove(0);
			}

			let idx = str.IndexOf('e');
			var pointIdx = str.IndexOf('.');
			var hasPoint = true;
			var expStartIdx = idx + 1;

			if (idx == -1)
			{
				if (isNeg)
				{
					str.Insert(0, '-');
				}

				return CastToRightFloatingPoint<T>(str);
			}

			if (str[idx + 1] == '+')
			{
				expStartIdx++;
			}

			let numStr = scope String(str, 0, idx);
			let expStr = StringView(str, expStartIdx, str.Length - expStartIdx);
			var exp = Int.Parse(expStr).Get();

			if (pointIdx == -1)
			{
				pointIdx = numStr.Length;
				hasPoint = false;
			}
			var newPointIdx = pointIdx + exp;

			if (hasPoint)
			{
				numStr.Replace('.', 'a');
			}

			if (newPointIdx == 0)
			{
				numStr.Insert(0, "0.");
			}
			else if (newPointIdx < 0)
			{
				var newNumStr = scope String();

				while (newPointIdx < 0)
				{
					newNumStr.Append('0');
					newPointIdx++;
				}
				newNumStr.Insert(0, "0.");
				numStr.Insert(0, newNumStr);
			}
			else if (newPointIdx > numStr.Length)
			{
				var zeroStr = scope String();
				var numberOfZero = (newPointIdx - numStr.Length) + ((hasPoint) ? (1): (0));

				while (numberOfZero > 0)
				{
					zeroStr.Append('0');
					numberOfZero--;
				}
				numStr.Append(zeroStr);
			}
			else if (pointIdx != 0)
			{
				numStr.Insert(newPointIdx, ".");
			}

			if (hasPoint)
			{
				numStr.Remove(numStr.IndexOf('a'));
			}

			if (isNeg)
			{
				numStr.Insert(0, '-');
			}

			return CastToRightFloatingPoint<T>(numStr);
		}

		private static Result<T, JSON_ERRORS> CastToRightFloatingPoint<T>(StringView str)
		{
			let type = typeof(T);
			T outNum = default;

			if (type == typeof(float))
			{
				var res = Float.Parse(str);
				Internal.MemCpy(&outNum, &res, type.Size);
			}
			else if (type == typeof(double))
			{
				var res = Double.Parse(str);
				Internal.MemCpy(&outNum, &res, type.Size);
			}
			else
			{
				return .Err(.INVALID_TYPE);
			}

			return .Ok(outNum);
		}

		public static JSON_LITERAL BoolToLiteral(bool b)
		{
			return (b) ? (JSON_LITERAL.TRUE) : (JSON_LITERAL.FALSE);
		}

		public static Result<bool, JSON_ERRORS> LiteralToBool(JSON_LITERAL l)
		{
			if (l == .NULL)
			{
				return .Err(.INVALID_LITERAL_VALUE);
			}

			return (l == .TRUE) ? (true) : (false);
		}
	}
}
