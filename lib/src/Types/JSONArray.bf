using System;
using System.Collections;
using System.Globalization;
using System.Reflection;
using JSON_Beef.Util;

namespace JSON_Beef.Types
{
	public class JSONArray
	{
		private List<Variant> _list = new .();
		private List<JSON_TYPES> _types = new .();

		public int Count
		{
			get
			{
				return _list.Count;
			}
		}

		public this()
		{
		}

		public this(JSONArray array)
		{
			for (int i = 0; i < array.Count; i++)
			{
				let otherVariant = array.GetVariant(i);
				let otherType = array.GetValueType(i);

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
					Add<JSONObject>(otherValue);
				case .ARRAY:
					Add<JSONArray>(otherValue);
				case .STRING:
					Add<String>(otherValue);
				case .INTEGER:
					Add<int64>(otherValue);
				case .FLOAT:
					Add<float>(otherValue);
				case .LITERAL:
					Add<bool>(otherValue);
				}
			}
		}

		public ~this()
		{
			for (var item in _list)
			{
				item.Dispose();
			}
			_list.Clear();
			_types.Clear();

			delete _list;
			delete _types;
		}

		public void AddRange<T>(Object range)
		{
			let list = range as List<T>;

			for (var item in list)
			{
				Add<T>(item);
			}
		}

		public void Add<T>(Object val)
		{
			Add(val, typeof(T));
		}

		private void Add(Object val, Type type)
		{
			if (type.IsPrimitive || (typeof(bool) == type))
			{
				if (type.IsIntegral)
				{
					_types.Add(JSON_TYPES.INTEGER);
				}
				else if (type.IsFloatingPoint)
				{
					_types.Add(JSON_TYPES.FLOAT);
				}
				else if (type == typeof(bool))
				{
					_types.Add(JSON_TYPES.LITERAL);
				}

				let str = scope String();
				val.ToString(str);
				str.ToLower();
				Add(str);
			}
			else
			{
				switch (type)
				{
				case typeof(JSONObject):
					Add((JSONObject)val);
					_types.Add(JSON_TYPES.OBJECT);
				case typeof(JSONArray):
					Add((JSONArray)val);
					_types.Add(JSON_TYPES.ARRAY);
				case typeof(String):
					Add((String)val);
					_types.Add(JSON_TYPES.STRING);
				default:
					Add((JSONObject)null);
					_types.Add(JSON_TYPES.OBJECT);
				}
			}
		}

		private void Add(String val)
		{
			if (val != null)
			{
				let v = new String(val);
				_list.Add(Variant.Create(v, true));
			}
			else
			{
				_list.Add(Variant.Create<String>(null, true));
			}
		}

		private void Add(JSONObject val)
		{
			if (val != null)
			{
				let v = new JSONObject(val);
				_list.Add(Variant.Create(v, true));
			}
			else
			{
				_list.Add(Variant.Create<JSONObject>(null, true));
			}
		}

		private void Add(JSONArray val)
		{
			if (val != null)
			{
				let v = new JSONArray(val);
				_list.Add(Variant.Create(v, true));
			}
			else
			{
				_list.Add(Variant.Create<JSONArray>(null, true));
			}
		}

		public Result<void, JSON_ERRORS> Get<T>(int idx, ref T dest)
		{
			var destVariant = Variant.Create<T>(default(T));
			if (Get(idx, ref destVariant) case .Err(let err))
			{
				return .Err(err);
			}

			dest = destVariant.Get<T>();

			return .Ok;
		}

		private Result<void, JSON_ERRORS> Get(int idx, ref Variant dest)
		{
			let type = dest.VariantType;

			if (idx > _list.Count)
			{
				return .Err(.INDEX_OUT_OF_BOUNDS);
			}

			if (!ContainsType(idx, type))
			{
				return .Err(.INVALID_TYPE);
			}

			let variant = GetVariant(idx);

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
					var res = JSONUtil.ParseNumber<float>(str);

					dest = Variant.Create(type, &res);
				}
				else if (typeof(bool) == type)
				{
					let str = variant.Get<String>();
					var res = JSONUtil.ParseBool(str);

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

		private bool ContainsType(int idx, Type type)
		{
			let variant = GetVariant(idx);
			let valueType = _types[idx];

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

		public override void ToString(String str)
		{
			var tempStr = scope String();

			str.Clear();
			str.Append("[");

			for (int i = 0; i < _list.Count; i++)
			{
				let variant = GetVariant(i);
				let type = GetValueType(i);

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
						Get<int64>(i, ref dest);
						tempStr.AppendF("{}", dest);
					case .FLOAT:
						float dest = default;
						Get<float>(i, ref dest);

						let numStr = scope String();
						let numInfo = scope NumberFormatInfo();
						numInfo.NumberDecimalDigits = 10;
						dest.ToString(numStr, "N", numInfo);
						tempStr.AppendF("{}", numStr);
					case .LITERAL:
						bool dest = default;
						Get<bool>(i, ref dest);
						let boolStr = scope String();
						dest.ToString(boolStr);
						boolStr.ToLower();
						tempStr.AppendF("{}", boolStr);
					case .OBJECT:
						var dest = scope JSONObject();
						Get<JSONObject>(i, ref dest);

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
						Get<JSONArray>(i, ref dest);

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
						Get<String>(i, ref dest);

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

				str.Append(tempStr);

				if (i != (_list.Count - 1))
				{
					str.Append(",");
				}

				tempStr.Clear();
			}

			str.Append("]");
		}

		public Variant GetVariant(int idx)
		{
			return _list[idx];
		}

		public JSON_TYPES GetValueType(int idx)
		{
			return _types[idx];
		}
	}
}
