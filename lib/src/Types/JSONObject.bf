using System;
using System.Collections;
using JSON_Beef.Util;

namespace JSON_Beef.Types
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
				case typeof(JSONObject):
					Add(key, value.Get<JSONObject>());
				case typeof(JSONArray):
					Add(key, value.Get<JSONArray>());
				case typeof(String):
					Add(key, value.Get<String>());
				default:
					if (value.Get<Object>() == null)
					{
						let k = new String(key);
						dictionary.Add(k, Variant.Create(default(Object)));
					}
				}
			}
		}

		public ~this()
		{
			for (var item in dictionary)
			{
				if (item.value.HasValue)
				{
					item.value.Dispose();
				}
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
				let type = typeof(T);

				if (type.IsPrimitive && (value.VariantType == typeof(String)))
				{
					if (type == typeof(bool))
					{
						bool res = JSONUtil.ParseBool(value.Get<String>());
						T outVal = default;
						Internal.MemCpy(&outVal, &res, sizeof(bool));
						return .Ok(outVal);
					}
					else
					{
						var res = JSONUtil.ParseNumber<T>(value.Get<String>());
						T outVal = default;
						Internal.MemCpy(&outVal, &res, type.Size);
						return .Ok(outVal);
					}
				}

				if ((typeof(T) == typeof(JSONObject)) || (typeof(T) == typeof(JSONArray)) || (typeof(T) == typeof(String)))
				{
					if (value.VariantType == typeof(T))
					{
						T ret = value.Get<T>();
						return .Ok(ret);
					}

					return .Err(.INVALID_RETURN_TYPE);
				}

				if (value.Get<Object>() == null)
				{
					return default(T);
				}	
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

				return .Err(.INVALID_TYPE);
			}

			return .Err(.KEY_NOT_FOUND);
		}

		public Variant GetVariant(String key)
		{
			return dictionary[key];
		}

		public void Add<T>(String key, Object val)
		{
			if (val == null)
			{
				let k = new String(key);
				dictionary.Add(k, Variant.Create(default(T)));
				return;
			}

			let type = typeof(T);

			if (type.IsPrimitive || (type == typeof(bool)))
			{
				let str = scope String();
				val.ToString(str);
				str.ToLower();
				Add(key, str);
				return;
			}

			switch (type)
			{
			case typeof(JSONObject):
				Add(key, (JSONObject)val);
			case typeof(JSONArray):
				Add(key, (JSONArray)val);
			case typeof(String):
				Add(key, (String)val);
			case typeof(bool):
				let str = scope String();
				bool b = (bool)val;
				b.ToString(str);
				Add(key, str);
			}
		}

		public bool Contains<T>(String key)
		{
			if (!dictionary.ContainsKey(key))
			{
				return false;
			}

			let variant = GetVariant(key);
			let type = typeof(T);

			if ((variant.VariantType == typeof(String)) && type.IsPrimitive)
			{
				if ((type == typeof(bool)) && JSONUtil.ParseBool(variant.Get<String>()) case .Ok(let val))
				{
					return true;
				}
				if (JSONUtil.ParseNumber<T>(variant.Get<String>()) case .Ok(let val))
				{
					return true;
				}
			}

			if ((type == typeof(JSONObject)) || (type == typeof(JSONArray)) || (type == typeof(String)))
			{
				if (variant.VariantType == type)
				{
					return true;
				}
			}

			if (variant.Get<Object>() == null)
			{
				return true;
			}

			return false;
		}

		private void Add(String key, String val)
		{
			let k = new String(key);
			let v = new String(val);
			dictionary.Add(k, Variant.Create(v, true));
		}

		private void Add(String key, JSONObject val)
		{
			let k = new String(key);
			let v = new JSONObject(val);
			dictionary.Add(k, Variant.Create(v, true));
		}

		private void Add(String key, JSONArray val)
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
