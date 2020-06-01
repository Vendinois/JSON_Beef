using System;

namespace JSON_Beef
{
	public class JSONUtil
	{
		public static Result<int, JSON_ERRORS> ParseInt(String json)
		{
			let idx = json.IndexOf('e');
			var expStartIdx = idx + 1;

			if (json.Contains('.'))
			{
				return .Err(.INVALID_NUMBER_REPRESENTATION);
			}

			if (idx == -1)
			{
				return .Ok(Int.Parse(json));
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

			return .Ok(Int.Parse(numStr));
		}

		public static Result<float, JSON_ERRORS> ParseFloat(String json)
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
				return .Ok(Float.Parse(str));
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

			return .Ok(Float.Parse(numStr));
		}

		public static JSON_LITERAL BoolToLiteral(bool b)
		{
			return (b) ? (JSON_LITERAL.TRUE) : (JSON_LITERAL.FALSE);
		}
	}
}
