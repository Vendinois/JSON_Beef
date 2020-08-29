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
				let value = array.GetVariant(i);

				switch (value.VariantType)
				{
				case typeof(JSONObject):
					Add(value.Get<JSONObject>());
				case typeof(JSONArray):
					Add(value.Get<JSONArray>());
				case typeof(String):
					Add(value.Get<String>());
				default:
					if (value.Get<Object>() == null)
					{
						_list.Add(Variant.Create(default(Object)));
					}
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
			if (type.IsPrimitive)
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
				}
			}
		}

		private void Add(String val)
		{
			let v = new String(val);
			_list.Add(Variant.Create(v, true));
		}

		private void Add(JSONObject val)
		{
			let v = new JSONObject(val);
			_list.Add(Variant.Create(v, true));
		}

		private void Add(JSONArray val)
		{
			let v = new JSONArray(val);
			_list.Add(Variant.Create(v, true));
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
				return .Err(.INDEX_OUT_OF_BOUNDS);
			}

			if (!ContainsType(idx, type))
			{
				return .Err(.INVALID_TYPE);
			}

			let variant = GetVariant(idx);
			dest = variant.Get<Object>();

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
	}
}
