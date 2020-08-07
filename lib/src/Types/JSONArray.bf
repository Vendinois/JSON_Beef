using System;
using System.Collections;
using System.Reflection;
using JSON_Beef.Util;

namespace JSON_Beef.Types
{
	public class JSONArray
	{
		private List<Variant> list;

		public int Count
		{
			get
			{
				return list.Count;
			}
		}

		public this()
		{
			list = new List<Variant>();
		}

		public this(JSONArray array)
		{
			list = new List<Variant>();

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
						list.Add(Variant.Create(default(Object)));
					}
				}
			}
		}

		public ~this()
		{
			for (var item in list)
			{
				item.Dispose();
			}

			list.Clear();
			delete list;
		}

		public void Add<T>(Object val)
		{
			if (val == null)
			{
				list.Add(Variant.Create(default(T)));
				return;
			}

			let type = typeof(T);

			if (type.IsPrimitive || (type == typeof(bool)))
			{
				let str = scope String();
				val.ToString(str);
				str.ToLower();
				Add(str);
				return;
			}

			switch (type)
			{
			case typeof(JSONObject):
				Add((JSONObject)val);
			case typeof(JSONArray):
				Add((JSONArray)val);
			case typeof(String):
				Add((String)val);
			}
		}

		private void Add(String val)
		{
			let v = new String(val);
			list.Add(Variant.Create(v, true));
		}

		private void Add(JSONObject val)
		{
			let v = new JSONObject(val);
			list.Add(Variant.Create(v, true));
		}

		private void Add(JSONArray val)
		{
			let v = new JSONArray(val);
			list.Add(Variant.Create(v, true));
		}

		public Result<T, JSON_ERRORS> Get<T>(int idx)
		{
			if (idx > list.Count)
			{
				return .Err(.INDEX_OUT_OF_BOUNDS);
			}

			let value = list[idx];

			let type = typeof(T);

			if ((value.VariantType == typeof(String)) && type.IsPrimitive)
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

			if ((type == typeof(JSONObject)) || (type == typeof(JSONArray)) || (type == typeof(String)))
			{
				if (value.VariantType == typeof(T))
				{
					T ret = value.Get<T>();
					return .Ok(ret);
				}
			}

			if (value.Get<Object>() == null)
			{
				return default(T);
			}

			return .Err(.INVALID_RETURN_TYPE);
		}

		public override void ToString(String str)
		{
			var tempStr = scope String();

			str.Clear();
			str.Append("[");

			for (int i = 0; i < list.Count; i++)
			{
				let variant = list[i];

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

				str.Append(tempStr);

				if (i != (list.Count - 1))
				{
					str.Append(",");
				}

				tempStr.Clear();
			}

			str.Append("]");
		}

		public Variant GetVariant(int idx)
		{
			return list[idx];
		}
	}
}
