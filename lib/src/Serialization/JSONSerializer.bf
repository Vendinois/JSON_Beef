using System;
using System.Collections;
using System.Reflection;
using JSON_Beef.Types;
using JSON_Beef.Attributes;

namespace JSON_Beef.Serialization
{
	public class JSONSerializer
	{
		public static Result<JSONObject> Serialize<T>(Object object) where T: JSONObject
		{
			if (object == null)
			{
				return .Err;
			}

			let json = new JSONObject();
			let type = object.GetType();
			var fields = type.GetFields();

			SerializeObjectBaseTypeInternal(object, json);

			for (var field in fields)
			{
				if (ShouldIgnore(field))
				{
					continue;
				}

				let res = SerializeObjectInternal(object, field, json);

				if (res == .Err)
				{
					return .Err;
				}
			}

			return .Ok(json);
		}

		public static Result<JSONArray> Serialize<T>(ref Object object) where T: JSONArray
		{
			if (!IsList(object) || (object == null))
			{
				return .Err;
			}

			let jsonArray = new JSONArray();
			let list = (List<Object>*)&object;

			for (var item in *list)
			{
				if (item == null)
				{
					jsonArray.Add<Object>(null);
				}
				else if (IsList(item))
				{
					let res = Serialize<JSONArray>(ref item);

					if (res == .Err)
					{
						return .Err;
					}

					jsonArray.Add<JSONArray>(res.Value);
				}
				else
				{
					let itemType = item.GetType();

					switch (itemType)
					{
					case typeof(String):
						jsonArray.Add<String>(item as String);
					case typeof(int):
						jsonArray.Add<int>((int)item);
					case typeof(int8):
						jsonArray.Add<int8>((int8)item);
					case typeof(int16):
						jsonArray.Add<int16>((int16)item);
					case typeof(int32):
						jsonArray.Add<int32>((int32)item);
					case typeof(int64):
						jsonArray.Add<int64>((int64)item);
					case typeof(uint):
						jsonArray.Add<uint>((uint)item);
					case typeof(uint8):
						jsonArray.Add<uint8>((uint8)item);
					case typeof(uint16):
						jsonArray.Add<uint16>((uint16)item);
					case typeof(uint32):
						jsonArray.Add<uint32>((uint32)item);
					case typeof(uint64):
						jsonArray.Add<uint64>((uint64)item);
					case typeof(char8):
						jsonArray.Add<char8>((char8)item);
					case typeof(char16):
						jsonArray.Add<char16>((char16)item);
					case typeof(char32):
						jsonArray.Add<char32>((char32)item);
					case typeof(float):
						jsonArray.Add<float>((float)item);
					case typeof(double):
						jsonArray.Add<double>((float)item);
					case typeof(bool):
						jsonArray.Add<bool>((bool)item);
					default:
						let res = Serialize<JSONObject>(item);

						if (res == .Err)
						{
							return .Err;
						}

						jsonArray.Add<JSONObject>(res.Value);
						delete res.Value;
					}
				}
			}

			return .Ok(jsonArray);
		}

		public static Result<String> Serialize<T>(Object object) where T: String
		{
			let str = new String();

			if (IsList(object))
			{
				var obj = object;
				let res = Serialize<JSONArray>(ref obj);

				if (res == .Err)
				{
					delete str;
					return .Err;
				}

				res.Value.ToString(str);
				delete res.Value;
			}
			else
			{
				let res = Serialize<JSONObject>(object);

				if (res == .Err)
				{
					delete str;
					return .Err;
				}

				res.Value.ToString(str);
				delete res.Value;
			}
			return .Ok(str);
		}

		private static bool IsList(Object object)
		{
			let type = object.GetType();
			let typeName = scope String();
			type.GetName(typeName);

			return typeName.Equals("List") || typeName.Equals("JsonList");
		}

		private static bool ShouldIgnore(FieldInfo field)
		{
			let shouldIgnore = field.GetCustomAttribute<IgnoreSerializeAttribute>();

			return ((shouldIgnore == .Ok) || field.HasFieldFlag(.PrivateScope) || field.HasFieldFlag(.Private));
		}

		private static Result<void> SerializeObjectInternal(Object object, FieldInfo field, JSONObject json)
		{
			let fieldName = scope String(field.Name);
			let fieldVariant = field.GetValue(object).Get();
			let fieldVariantType = fieldVariant.VariantType;

			if (fieldVariantType.IsPrimitive)
			{
				switch (fieldVariantType)
				{
				case typeof(int):
					json.Add<int>(fieldName, fieldVariant.Get<int>());
				case typeof(int8):
					json.Add<int8>(fieldName, fieldVariant.Get<int8>());
				case typeof(int16):
					json.Add<int16>(fieldName, fieldVariant.Get<int16>());
				case typeof(int32):
					json.Add<int32>(fieldName, fieldVariant.Get<int32>());
				case typeof(int64):
					json.Add<int64>(fieldName, fieldVariant.Get<int64>());
				case typeof(uint):
					json.Add<uint>(fieldName, fieldVariant.Get<uint>());
				case typeof(uint8):
					json.Add<uint8>(fieldName, fieldVariant.Get<uint8>());
				case typeof(uint16):
					json.Add<uint16>(fieldName, fieldVariant.Get<uint16>());
				case typeof(uint32):
					json.Add<uint32>(fieldName, fieldVariant.Get<uint32>());
				case typeof(uint64):
					json.Add<uint64>(fieldName, fieldVariant.Get<uint64>());
				case typeof(char8):
					json.Add<char8>(fieldName, fieldVariant.Get<char8>());
				case typeof(char16):
					json.Add<char16>(fieldName, fieldVariant.Get<char16>());
				case typeof(char32):
					json.Add<char32>(fieldName, fieldVariant.Get<char32>());
				case typeof(float):
					json.Add<float>(fieldName, fieldVariant.Get<float>());
				case typeof(double):
					json.Add<double>(fieldName, fieldVariant.Get<double>());
				case typeof(bool):
					json.Add<bool>(fieldName, fieldVariant.Get<bool>());
				default:
					return .Err;
				}
			}
			else if (fieldVariantType.IsObject)
			{
				var fieldValue = fieldVariant.Get<Object>();

				if (fieldValue == null)
				{
					json.Add<Object>(fieldName, null);
					return .Ok;
				}

				SerializeObjectBaseTypeInternal(fieldValue, json);

				if (IsList(fieldValue))
				{
					let res = Serialize<JSONArray>(ref fieldValue);

					if (res == .Err)
					{
						return .Err;
					}

					json.Add<JSONArray>(fieldName, res.Value);
					delete res.Value;
				}
				else
				{
					switch (fieldVariantType)
					{
					case typeof(String):
						json.Add<String>(fieldName, (String)fieldValue);
					default:
						let res = Serialize<JSONObject>(fieldValue);

						if (res == .Err)
						{
							delete json;
							return .Err;
						}

						json.Add<JSONObject>(fieldName, res.Value);
						delete res.Value;
					}
				}
			}

			return .Ok;
		}

		private static Result<void> SerializeObjectBaseTypeInternal(Object object, JSONObject json)
		{
			let type = object.GetType();
			let baseType = type.BaseType;

			// It is not an error to have the same base type as the current type.
			// It only tells that we arrived at the top of the inheritence chain.
			// So I exit now to break any infinite recursion loop.
			if (type == baseType)
			{
				return .Ok;
			}

			let fields = baseType.GetFields();

			for (var field in fields)
			{
				if (ShouldIgnore(field))
				{
					continue;
				}

				let fieldName = scope String(field.Name);
				let fieldVariant = field.GetValue(object).Get();
				let fieldVariantType = fieldVariant.VariantType;
				var fieldValue = fieldVariant.Get<Object>();

				SerializeObjectBaseTypeInternal(fieldValue, json);

				if (fieldValue == null)
				{
					json.Add<Object>(fieldName, null);
				}
				else if (IsList(fieldValue))
				{
					let res = Serialize<JSONArray>(ref fieldValue);

					if (res == .Err)
					{
						return .Err;
					}

					json.Add<JSONArray>(fieldName, res.Value);
					delete res.Value;
				}
				else
				{
					switch (fieldVariantType)
					{
					case typeof(String):
						json.Add<String>(fieldName, (String)fieldValue);
					case typeof(int):
						json.Add<int>(fieldName, (int)fieldValue);
					case typeof(int8):
						json.Add<int8>(fieldName, (int8)fieldValue);
					case typeof(int16):
						json.Add<int16>(fieldName, (int16)fieldValue);
					case typeof(int32):
						json.Add<int32>(fieldName, (int32)fieldValue);
					case typeof(int64):
						json.Add<int64>(fieldName, (int64)fieldValue);
					case typeof(uint):
						json.Add<uint>(fieldName, (uint)fieldValue);
					case typeof(uint8):
						json.Add<uint8>(fieldName, (uint8)fieldValue);
					case typeof(uint16):
						json.Add<uint16>(fieldName, (uint16)fieldValue);
					case typeof(uint32):
						json.Add<uint32>(fieldName, (uint32)fieldValue);
					case typeof(uint64):
						json.Add<uint64>(fieldName, (uint64)fieldValue);
					case typeof(char8):
						json.Add<char8>(fieldName, (char8)fieldValue);
					case typeof(char16):
						json.Add<char16>(fieldName, (char16)fieldValue);
					case typeof(char32):
						json.Add<char32>(fieldName, (char32)fieldValue);
					case typeof(float):
						json.Add<float>(fieldName, (float)fieldValue);
					case typeof(double):
						json.Add<double>(fieldName, (double)fieldValue);
					case typeof(bool):
						json.Add<bool>(fieldName, (bool)fieldValue);
					default:
						let res = Serialize<JSONObject>(fieldValue);

						if (res == .Err)
						{
							delete json;
							return .Err;
						}

						json.Add<JSONObject>(fieldName, res.Value);
						delete res.Value;
					}
				}
			}

			return .Ok;
		}

		private static Result<void> SerializeArrayInternal(Object object, FieldInfo field, JSONArray json)
		{
			let fieldVariant = field.GetValue(object).Get();
			let fieldVariantType = fieldVariant.VariantType;
			var fieldValue = fieldVariant.Get<Object>();

			if (fieldValue == null)
			{
				json.Add<Object>(null);
			}
			else if (IsList(fieldValue))
			{
				let res = Serialize<JSONArray>(ref fieldValue);

				if (res == .Err)
				{
					return .Err;
				}

				json.Add<JSONArray>(res.Value);
				delete res.Value;
			}
			else
			{
				switch (fieldVariantType)
				{
				case typeof(String):
					json.Add<String>((String)fieldValue);
				case typeof(int):
					json.Add<int>((int)fieldValue);
				case typeof(int8):
					json.Add<int8>((int8)fieldValue);
				case typeof(int16):
					json.Add<int16>((int16)fieldValue);
				case typeof(int32):
					json.Add<int32>((int32)fieldValue);
				case typeof(int64):
					json.Add<int64>((int64)fieldValue);
				case typeof(uint):
					json.Add<uint>((uint)fieldValue);
				case typeof(uint8):
					json.Add<uint8>((uint8)fieldValue);
				case typeof(uint16):
					json.Add<uint16>((uint16)fieldValue);
				case typeof(uint32):
					json.Add<uint32>((uint32)fieldValue);
				case typeof(char8):
					json.Add<char8>((char8)fieldValue);
				case typeof(char16):
					json.Add<char16>((char16)fieldValue);
				case typeof(char32):
					json.Add<char32>((char32)fieldValue);
				case typeof(uint64):
					json.Add<uint64>((uint64)fieldValue);
				case typeof(float):
					json.Add<float>((float)fieldValue);
				case typeof(double):
					json.Add<double>((double)fieldValue);
				case typeof(bool):
					json.Add<bool>((bool)fieldValue);
				default:
					let res = Serialize<JSONObject>(fieldValue);

					if (res == .Err)
					{
						delete json;
						return .Err;
					}

					json.Add<JSONObject>(res.Value);
					delete res.Value;
				}
			}
			return .Ok;
		}
	}
}
