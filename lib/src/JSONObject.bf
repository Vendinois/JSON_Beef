using System;
using System.Collections;

namespace JSON_Beef
{
	public class JSONObject
	{
		private Dictionary<String, Variant> dictionary;

		public this()
		{
			dictionary = new Dictionary<String, Variant>();
		}

		public this(JSONObject obj)
		{
			dictionary = new Dictionary<String, Variant>();

			var keys = obj.dictionary.Keys;

			while (keys.MoveNext())
			{
				let key = keys.Current;
				let value = obj.GetVariant(key);

				switch (value.VariantType)
				{
				case typeof(int):
					Add(key, value.Get<int>());
				case typeof(float):
					Add(key, value.Get<float>());
				case typeof(JSON_LITERAL):
					Add(key, value.Get<JSON_LITERAL>());
				case typeof(JSONObject):
					Add(key, value.Get<JSONObject>());
				case typeof(JSONArray):
					Add(key, value.Get<JSONArray>());
				case typeof(String):
					Add(key, value.Get<String>());
				default:
					break;
				}
			}
		}

		public ~this()
		{
			for (var item in dictionary)
			{
				item.value.Dispose();
				delete item.key;
			}

			dictionary.Clear();

			delete dictionary;
		}

		public Result<T, JSON_ERRORS> Get<T>(String key)
		{
			if (dictionary.ContainsKey(key))
			{
				let value = dictionary[key];

				if (value.VariantType == typeof(T) || (value.VariantType.IsInteger && typeof(T).IsInteger))
				{
					T ret = value.Get<T>();
					return .Ok(ret);
				}

				return .Err(.INVALID_TYPE);
			}

			return .Err(.KEY_NOT_FOUND);
		}

		public Result<Object, JSON_ERRORS> Get(String key, Type type)
		{
			if (dictionary.ContainsKey(key))
			{
				let value = dictionary[key];

				if (value.VariantType == type)
				{
					let ret = value.Get<Object>();
					return .Ok(ret);
				}
				else if (value.VariantType == typeof(JSON_LITERAL) && value.Get<JSON_LITERAL>() == .NULL)
				{
					return .Ok(null);
				}

				return .Err(.INVALID_TYPE);
			}

			return .Err(.KEY_NOT_FOUND);
		}

		public Variant GetVariant(String key)
		{
			return dictionary[key];
		}

		public bool Contains<T>(String key)
		{
			if (!dictionary.ContainsKey(key))
			{
				return false;
			}

			let variant = GetVariant(key);

			switch (typeof(T))
			{
			case typeof(bool):
				return ((variant.VariantType == typeof(JSON_LITERAL)) && (variant.Get<JSON_LITERAL>() != .NULL));
			case variant.VariantType:
				return true;
			default:
				return false;
			}
		}

		public bool Contains(String key, Type type)
		{
			if (!dictionary.ContainsKey(key))
			{
				return false;
			}

			let variant = GetVariant(key);

			switch (type)
			{
			case typeof(bool):
				return ((variant.VariantType == typeof(JSON_LITERAL)) && (variant.Get<JSON_LITERAL>() != .NULL));
			case variant.VariantType:
				return true;
			default:
				return false;
			}
		}

		public void Add(String key, String val)
		{
			let k = new String(key);
			let v = new String(val);
			dictionary.Add(k, Variant.Create(v, true));
		}

		public void Add(String key, int val)
		{
			let k = new String(key);
			let v = val;
			dictionary.Add(k, Variant.Create(v));
		}

		public void Add(String key, float val)
		{
			let k = new String(key);
			let v = val;
			dictionary.Add(k, Variant.Create(v));
		}

		public void Add(String key, JSON_LITERAL val)
		{
			let k = new String(key);
			let v = val;
			dictionary.Add(k, Variant.Create(v));
		}

		public void Add(String key, JSONObject val)
		{
			let k = new String(key);
			let v = new JSONObject(val);
			dictionary.Add(k, Variant.Create(v, true));
		}

		public void Add(String key, JSONArray val)
		{
			let k = new String(key);
			let v = new JSONArray(val);
			dictionary.Add(k, Variant.Create(v, true));
		}

		public override void ToString(String str)
		{
			var keys = dictionary.Keys;
			var tempStr = scope String();

			str.Clear();
			str.Append("{");

			var canParse = keys.MoveNext();
			while (canParse)
			{
				let currentKey = keys.Current;

				let variant = dictionary[currentKey];

				switch (variant.VariantType)
				{
				case typeof(String):
					tempStr.AppendF("\"{}\"", variant.Get<String>());
				case typeof(int):
					variant.Get<Int>().ToString(tempStr);
				case typeof(float):
					variant.Get<Float>().ToString(tempStr);
				case typeof(JSON_LITERAL):
					variant.Get<JSON_LITERAL>().ToString(tempStr);
					tempStr.ToLower();
				case typeof(JSONObject):
					variant.Get<JSONObject>().ToString(tempStr);
				case typeof(JSONArray):
					variant.Get<JSONArray>().ToString(tempStr);
				default:
					tempStr.Set(String.Empty);
				}
				//str.Append(tempStr);

				str.AppendF("\"{}\":{}", currentKey, tempStr);

				if (canParse = keys.MoveNext())
				{
					str.Append(",");
				}

				tempStr.Clear();
			}

			str.Append("}");
		}
	}
}
