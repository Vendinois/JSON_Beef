using System;
using System.Collections;
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
			delete _list;
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

		public Result<void, JSON_ERRORS> Get<T>(int idx, out T dest)
		{
			Object obj = default;
			if (Get(idx, out obj, typeof(T)) case .Err(let err))
			{
				return .Err(err);
			}


			dest = (T)obj;
			return .Ok;
		}

		private Result<void, JSON_ERRORS> Get(int idx, out Object dest, Type type)
		{
			if (idx > _list.Count)
			{
				dest = null;
				return .Err(.INDEX_OUT_OF_BOUNDS);
			}

			if (!ContainsType(idx, type))
			{
				dest = null;
				return .Err(.INVALID_TYPE);
			}

			let variant = GetVariant(idx);

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
						tempStr.AppendF("{}", Get<int64>(i, out dest));
					}
					else if (variantType.IsFloatingPoint)
					{
						float dest = default;
						tempStr.AppendF("{}", Get<float>(i, out dest));
					}
					else if (variantType == typeof(bool))
					{
						bool dest = default;
						tempStr.AppendF("{}", Get<bool>(i, out dest));
					}
					else if (variantType == typeof(String))
					{
						var dest = scope String();
						tempStr.AppendF("\"{}\"", Get<String>(i, out dest));
					}
					else if (variantType == typeof(JSONObject))
					{
						var dest = scope JSONObject();
						Get<JSONObject>(i, out dest);

						dest.ToString(tempStr);
					}
					else if (variantType == typeof(JSONArray))
					{
						var dest = scope JSONArray();
						Get<JSONArray>(i, out dest);

						dest.ToString(tempStr);
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
