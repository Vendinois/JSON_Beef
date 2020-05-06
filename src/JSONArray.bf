using System;
using System.Collections;

namespace JSON_Beef
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
				case typeof(int):
					Add(value.Get<int>());
				case typeof(float):
					Add(value.Get<float>());
				case typeof(JSON_LITERAL):
					Add(value.Get<JSON_LITERAL>());
				case typeof(JSONObject):
					Add(value.Get<JSONObject>());
				case typeof(JSONArray):
					Add(value.Get<JSONArray>());
				case typeof(String):
					Add(value.Get<String>());
				default:
					break;
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

		public void Add(String val)
		{
			let v = new String(val);
			list.Add(Variant.Create(v, true));
		}

		public void Add(int val)
		{
			let v = val;
			list.Add(Variant.Create(v));
		}

		public void Add(float val)
		{
			let v = val;
			list.Add(Variant.Create(v));
		}

		public void Add(JSON_LITERAL val)
		{
			let v = val;
			list.Add(Variant.Create(v));
		}

		public void Add(JSONObject val)
		{
			let v = new JSONObject(val);
			list.Add(Variant.Create(v, true));
		}

		public void Add(JSONArray val)
		{
			let v = new JSONArray(val);
			list.Add(Variant.Create(v, true));
		}

		public T Get<T>(int idx)
		{
			if (idx > list.Count)
			{
				return default;
			}

			let value = list[idx];

			if (value.VariantType == typeof(T))
			{
				T ret = value.Get<T>();
				return ret;
			}

			return default;
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
