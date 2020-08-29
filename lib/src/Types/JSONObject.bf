using System;
using System.Collections;
using JSON_Beef.Util;

namespace JSON_Beef.Types
{
	public class JSONObject
	{
		private Dictionary<String, Variant> _dictionary = new .();
		private Dictionary<String, JSON_TYPES> _types = new .();

		public this() {}

		public this(JSONObject obj)
		{
			var keys = obj._dictionary.Keys;

			while (keys.MoveNext())
			{
				let key = keys.Current;
				let value = obj.GetVariant(key);
				let type = obj.GetValueType(key);

				if (!value.HasValue)
				{
					let k = new String(key);
					_dictionary.Add(k, Variant.Create(default(Object)));
				}
				else
				{
					switch (value.VariantType)
					{
					case typeof(JSONObject):
						Add(key, value.Get<JSONObject>());
					case typeof(JSONArray):
						Add(key, value.Get<JSONArray>());
					case typeof(String):
						Add(key, value.Get<String>());
					}
				}

				let k = new String(key);
				_types[k] = type;
			}
		}

		public ~this()
		{
			for (var item in _dictionary)
			{
				if (item.value.HasValue)
				{
					item.value.Dispose();
				}
				delete item.key;
			}
			_dictionary.Clear();
			_types.Clear();

			for (var item in _types)
			{
				delete item.key;
			}
			delete _types;
			delete _dictionary;
		}

		public Result<T, JSON_ERRORS> Get<T>(String key)
		{
			return Get<T>(key, true);
		}

		public Result<Object, JSON_ERRORS> Get(String key, Type type)
		{
			return Get(key, type, true);
		}

		private Result<T, JSON_ERRORS> Get<T>(String key, bool check)
		{
			T value = default;
			return G<T>(key, check, out value);

			let result = Get(key, typeof(T), check);

			switch (result)
			{
			case .Err(let err):
				return .Err(err);
			case .Ok(let val):
				return (T)val;
			}
		}

		private Result<T, JSON_ERRORS> G<T>(String key, bool check, out T val)
		{
			let res = Get(key, typeof(T), check);

			return val;
		}

		private Result<Object, JSON_ERRORS> Get(String key, Type type, bool check)
		{
			if (check && !Contains(key, type))
			{
				return .Err(.KEY_NOT_FOUND);
			}

			let variant = GetVariant(key);

			return variant.Get<Object>();
		}

		private Result<Object, JSON_ERRORS> Get(String key, Type type, bool check, out Object val)
		{
			if (check && !Contains(key, type))
			{
				return .Err(.KEY_NOT_FOUND);
			}

			let variant = GetVariant(key);

			val = variant.Get<Object>();

			return val;
		}

		public Variant GetVariant(String key)
		{
			return _dictionary[key];
		}

		public JSON_TYPES GetValueType(String key)
		{
			return _types[key];
		}

		public void Add<T>(String key, Object val)
		{
			Add(key, val, typeof(T));
		}

		public void Add(String key, Object val, Type type)
		{
			let k = new String(key);
			if (type.IsPrimitive)
			{
				if (type.IsIntegral)
				{
					_types[k] = JSON_TYPES.INTEGER;
				}
				else if (type.IsFloatingPoint)
				{
					_types[k] = JSON_TYPES.FLOAT;
				}
				else if (type == typeof(bool))
				{
					_types[k] = JSON_TYPES.LITERAL;
				}

				let str = scope String();
				val.ToString(str);
				str.ToLower();
				Add(key, str);
			}
			else
			{
				switch (type)
				{
				case typeof(JSONObject):
					Add(key, (JSONObject)val);
					_types[k] = JSON_TYPES.OBJECT;
				case typeof(JSONArray):
					Add(key, (JSONArray)val);
					_types[k] = JSON_TYPES.ARRAY;
				case typeof(String):
					Add(key, (String)val);
					_types[k] = JSON_TYPES.STRING;
				}
			}
		}

		public bool Contains<T>(String key)
		{
			return Contains(key, typeof(T));
		}

		public bool Contains(String key, Type type)
		{
			if (!_dictionary.ContainsKey(key) || (!_types.ContainsKey(key)))
			{
				return false;
			}

			return ContainsType(key, type);
		}

		private bool ContainsType(String key, Type type)
		{
			let variant = GetVariant(key);
			let valueType = _types[key];

			if (type.IsPrimitive)
			{
				if (type.IsIntegral && (valueType != JSON_TYPES.INTEGER))
				{
					return false;
				}
				else if (type.IsFloatingPoint && (valueType != JSON_TYPES.FLOAT))
				{
					return false;
				}
				else if (((type == typeof(bool) && (valueType != JSON_TYPES.LITERAL))) || ((type == null) && (valueType != JSON_TYPES.LITERAL)))
				{
					return false;
				}
			}
			else
			{
				if ((variant.VariantType == typeof(JSONObject)) && (valueType != JSON_TYPES.OBJECT))
				{
					return false;
				}
				else if ((variant.VariantType == typeof(JSONArray)) && (valueType != JSON_TYPES.ARRAY))
				{
					return false;
				}
				else if ((variant.VariantType == typeof(String)) && (valueType != JSON_TYPES.STRING))
				{
					return false;
				}
			}

			return true;
		}

		private void Add(String key, String val)
		{
			let k = new String(key);
			if (val != null)
			{
				let v = new String(val);
				_dictionary.Add(k, Variant.Create(v, true));
			}
			else
			{
				_dictionary.Add(k, Variant.Create<String>(null, true));
			}
		}

		private void Add(String key, JSONObject val)
		{
			let k = new String(key);
			if (val != null)
			{
				let v = new JSONObject(val);
				_dictionary.Add(k, Variant.Create(v, true));
			}
			else
			{
				_dictionary.Add(k, Variant.Create<JSONObject>(null, true));
			}
		}

		private void Add(String key, JSONArray val)
		{
			let k = new String(key);
			if (val != null)
			{
				let v = new JSONArray(val);
				_dictionary.Add(k, Variant.Create(v, true));
			}
			else
			{
				_dictionary.Add(k, Variant.Create<JSONArray>(null, true));
			}
		}

		public override void ToString(String str)
		{
			var keys = _dictionary.Keys;
			var tempStr = scope String();

			str.Clear();
			str.Append("{");

			var canParse = keys.MoveNext();
			while (canParse)
			{
				let currentKey = keys.Current;

				let variant = _dictionary[currentKey];
				let variantType = variant.VariantType;

				if (!variant.HasValue)
				{
					tempStr.Append("null");
				}
				else
				{
					if (variantType.IsIntegral)
					{
						tempStr.AppendF("{}", Get<int64>(currentKey, false));
					}
					else if (variantType.IsFloatingPoint)
					{
						tempStr.AppendF("{}", Get<float>(currentKey, false));
					}
					else if (variantType == typeof(bool))
					{
						tempStr.AppendF("{}", Get<bool>(currentKey, false));
					}
					else if (variantType == typeof(String))
					{
						tempStr.AppendF("\"{}\"", Get<String>(currentKey, false));
					}
					else if (variantType == typeof(JSONObject))
					{
						Get<JSONObject>(currentKey, false).ToString(tempStr);
					}
					else if (variantType == typeof(JSONArray))
					{
						Get<JSONArray>(currentKey, false).ToString(tempStr);
					}
				}

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
