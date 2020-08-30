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
				var otherVariant = obj.GetVariant(key);
				let otherType = obj.GetValueType(key);

				Object otherValue = default;

				if (!otherVariant.HasValue)
				{
					otherValue = null;
				}
				else
				{
					otherValue = otherVariant.Get<Object>();
				}

				switch (otherType)
				{
				case .OBJECT:
					Add<JSONObject>(key, otherValue);
				case .ARRAY:
					Add<JSONArray>(key, otherValue);
				case .STRING:
					Add<String>(key, otherValue);
				case .INTEGER:
					Add<int64>(key, otherValue);
				case .FLOAT:
					Add<float>(key, otherValue);
				case .LITERAL:
					Add<bool>(key, otherValue);
				}
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

		public Result<void, JSON_ERRORS> Get<T>(String key, out T dest)
		{
			return Get<T>(key, out dest, true);
		}

		private Result<void, JSON_ERRORS> Get<T>(String key, out T dest, bool check)
		{
			Object obj = default;
			if (Get(key, typeof(T), out obj, check) case .Err(let err))
			{
				return .Err(err);
			}

			dest = (T)obj;

			return .Ok;
		}

		public Result<void, JSON_ERRORS> Get(String key, Type type, out Object dest)
		{
			Object obj = default;
			if (Get(key, type, out obj, true) case .Err(let err))
			{
				return .Err(err);
			}

			dest = obj;
			return .Ok;
		}

		private Result<void, JSON_ERRORS> Get(String key, Type type, out Object dest, bool check)
		{
			if (check && !Contains(key, type))
			{
				return .Err(.KEY_NOT_FOUND);
			}

			let variant = GetVariant(key);
			dest = variant.Get<Object>();

			return .Ok;
		}

		private Result<void, JSON_ERRORS> Get(String key, Type type, bool check, out Object dest)
		{
			if (check && !Contains(key, type))
			{
				return .Err(.KEY_NOT_FOUND);
			}

			let variant = GetVariant(key);

			if (variant.HasValue)
			{
				if (type.IsInteger)
				{
					let str = variant.Get<String>();
					let res = JSONUtil.ParseNumber<int64>(str);

					dest = res.Value;
				}
				else if (type.IsFloatingPoint)
				{
					let str = variant.Get<String>();
					let res = JSONUtil.ParseNumber<float>(str);

					dest = res.Value;
				}
				else if (typeof(bool) == type)
				{
					let str = variant.Get<String>();
					let res = JSONUtil.ParseBool(str);

					dest = res.Value;
				}
				else if ((type == typeof(JSONObject)) || (type == typeof(JSONArray)) || (type == typeof(String))
					&& (variant.VariantType == type))
				{
					dest = variant.Get<Object>();
				}
				else
				{
					dest = null;
					return .Err(.INVALID_TYPE);
				}
			}

			dest = null;

			return .Ok;
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
			if (type.IsPrimitive || (typeof(bool) == type))
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
				default:
					Add(key, (JSONObject)val);
					_types[k] = JSON_TYPES.OBJECT;
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

				let variant = GetVariant(currentKey);
				let variantType = variant.VariantType;

				if (!variant.HasValue)
				{
					tempStr.Append("null");
				}
				else
				{
					if (variantType.IsIntegral)
					{
						int64 dest = default;
						tempStr.AppendF("{}", Get<int64>(currentKey, out dest, false));
					}
					else if (variantType.IsFloatingPoint)
					{
						float dest = default;
						tempStr.AppendF("{}", Get<float>(currentKey, out dest, false));
					}
					else if (variantType == typeof(bool))
					{
						bool dest = default;
						tempStr.AppendF("{}", Get<bool>(currentKey, out dest, false));
					}
					else if (variantType == typeof(String))
					{
						var dest = scope String();
						tempStr.AppendF("\"{}\"", Get<String>(currentKey, out dest, false));
					}
					else if (variantType == typeof(JSONObject))
					{
						var dest = scope JSONObject();
						Get<JSONObject>(currentKey, out dest, false);

						dest.ToString(tempStr);
					}
					else if (variantType == typeof(JSONArray))
					{
						var dest = scope JSONArray();
						Get<JSONArray>(currentKey, out dest, false);

						dest.ToString(tempStr);
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
