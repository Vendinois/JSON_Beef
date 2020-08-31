using System;
using System.Collections;
using System.Globalization;
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

			for (var item in _types)
			{
				delete item.key;
			}
			_types.Clear();
			delete _types;
			delete _dictionary;
		}

		public Result<void, JSON_ERRORS> Get<T>(String key, ref T dest)
		{
			var destVariant = Variant.Create<T>(default(T));
			if (Get(key, ref destVariant) case .Err(let err))
			{
				return .Err(err);
			}

			dest = destVariant.Get<T>();

			return .Ok;
		}

		private Result<void, JSON_ERRORS> Get(String key, ref Variant dest)
		{
			let type = dest.VariantType;
			if (!ContainsKey(key))
			{
				return .Err(.KEY_NOT_FOUND);
			}

			if (!ContainsType(key, type))
			{
				return .Err(.INVALID_TYPE);
			}

			let variant = GetVariant(key);

			if (variant.HasValue)
			{
				if (type.IsInteger)
				{
					let str = variant.Get<String>();
					var res = JSONUtil.ParseNumber<int64>(str).Value;

					dest = Variant.Create(type, &res);
				}
				else if (type.IsFloatingPoint)
				{
					let str = variant.Get<String>();
					var res = JSONUtil.ParseNumber<float>(str).Value;

					dest = Variant.Create(type, &res);
				}
				else if (typeof(bool) == type)
				{
					let str = variant.Get<String>();
					var res = JSONUtil.ParseBool(str).Value;

					dest = Variant.Create(type, &res);
				}
				else if ((type == typeof(JSONObject)) && (variant.VariantType == type))
				{
					var res = variant.Get<JSONObject>();
					dest = Variant.Create<JSONObject>(res);
				}
				else if ((type == typeof(JSONArray)) && (variant.VariantType == type))
				{
					var res = variant.Get<JSONArray>();
					dest = Variant.Create<JSONArray>(res);
				}
				else if ((type == typeof(String)) && (variant.VariantType == type))
				{
					var res = variant.Get<String>();
					dest = Variant.Create<String>(res);
				}
			}

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
					_types.Add(k, JSON_TYPES.INTEGER);
				}
				else if (type.IsFloatingPoint)
				{
					_types.Add(k, JSON_TYPES.FLOAT);
				}
				else if (type == typeof(bool))
				{
					_types.Add(k, JSON_TYPES.LITERAL);
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
					_types.Add(k, JSON_TYPES.OBJECT);
				case typeof(JSONArray):
					Add(key, (JSONArray)val);
					_types.Add(k, JSON_TYPES.ARRAY);
				case typeof(String):
					Add(key, (String)val);
					_types.Add(k, JSON_TYPES.STRING);
				default:
					Add(key, (JSONObject)val);
					_types.Add(k, JSON_TYPES.OBJECT);
				}
			}
		}

		public bool Contains<T>(String key)
		{
			return ContainsKey<T>(key) && ContainsType<T>(key);
		}

		public bool ContainsKey<T>(String key)
		{
			return ContainsKey(key);
		}

		public bool ContainsKey(String key)
		{
			if (!_dictionary.ContainsKey(key) || (!_types.ContainsKey(key)))
			{
				return false;
			}

			return true;
		}

		public bool ContainsType<T>(String key)
		{
			return ContainsType(key, typeof(T));
		}

		public bool ContainsType(String key, Type type)
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
				let type = GetValueType(currentKey);

				if (!variant.HasValue)
				{
					tempStr.Append("null");
				}
				else
				{
					switch (type)
					{
					case .INTEGER:
						int64 dest = default;
						Get<int64>(currentKey, ref dest);
						tempStr.AppendF("{}", dest);
					case .FLOAT:
						float dest = default;
						Get<float>(currentKey, ref dest);

						let numStr = scope String();
						let numInfo = scope NumberFormatInfo();
						numInfo.NumberDecimalDigits = 10;

						dest.ToString(numStr, "N", numInfo);
						tempStr.AppendF("{}", numStr);
					case .LITERAL:
						bool dest = default;
						Get<bool>(currentKey, ref dest);
						let boolStr = scope String();
						dest.ToString(boolStr);
						boolStr.ToLower();
						tempStr.AppendF("{}", boolStr);
					case .OBJECT:
						var dest = scope JSONObject();
						Get<JSONObject>(currentKey, ref dest);

						if (dest != null)
						{
							dest.ToString(tempStr);
						}
						else
						{
							tempStr.Append("null");
						}
					case .ARRAY:
						var dest = scope JSONArray();
						Get<JSONArray>(currentKey, ref dest);

						if (dest != null)
						{
							dest.ToString(tempStr);
						}
						else
						{
							tempStr.Append("null");
						}
					case .STRING:
						var dest = scope String();
						Get<String>(currentKey, ref dest);

						if (dest != null)
						{
							tempStr.AppendF("\"{}\"", dest);
						}
						else
						{
							tempStr.Append("null");
						}
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
