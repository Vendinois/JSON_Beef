using System;
using System.Collections;
using System.Reflection;
using JSON_Beef.Attributes;
using JSON_Beef.Types;
using JSON_Beef.Util;

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

			Variant from = default;

			if (Variant.CreateFromBoxed(object) case .Ok(let val))
			{
				from = val;
			}
			else
			{
				return .Err;
			}

			let json = new JSONObject();
			if (SerializeObject(from, json) case .Err)
			{
				return .Err;
			}

			return .Ok(json);
		}

		public static Result<JSONArray> Serialize<T>(Object listObject) where T: JSONArray
		{
			var object = listObject;
			if (!TypeChecker.IsTypeList(object) || (object == null))
			{
				return .Err;
			}

			Variant from = default;

			if (Variant.CreateFromBoxed(listObject) case .Ok(let val))
			{
				from = val;
			}
			else
			{
				return .Err;
			}

			let json = new JSONArray();
			if (SerializeArray(from, json) case .Err)
			{
				return .Err;
			}

			return .Ok(json);
		}

		private static Result<void> SerializeObject(Variant from, JSONObject dest)
		{
			if (!from.HasValue)
			{
				return .Ok;
			}

			let type = from.VariantType;
			let fields = type.GetFields();
			var error = false;

			for (var field in fields)
			{
				let fieldName = scope String(field.Name);
				let fieldType = field.FieldType;
				Variant variant = default;

				if (from.VariantType.IsObject)
				{
					variant = field.GetValue(from.Get<Object>());
				}
				else if (from.VariantType.IsStruct)
				{
					variant = field.GetValue(from);
				}

				if (TypeChecker.IsTypeList(fieldType))
				{
					let array = scope JSONArray();

					if (SerializeArray(variant, array) case .Err)
					{
						error = true;
					}
					else
					{
						dest.Add<JSONArray>(fieldName, array);
					}
				}
				else if (TypeChecker.IsUserObject(fieldType))
				{
					let obj = scope JSONObject();

					if (SerializeObject(variant, obj) case .Err)
					{
						error = true;
					}
					else
					{
						dest.Add<JSONObject>(fieldName, obj);
					}
				}
				else if (TypeChecker.IsPrimitive(fieldType))
				{
					if (SerializePrimitive(fieldName, variant, dest) case .Err)
					{
						error = true;
					}
				}
				else
				{
					error = true;
				}

				if (error)
				{
					break;
				}
			}

			return .Ok;
		}

		private static Result<void> SerializeArray(Variant fieldVariant, JSONArray dest)
		{
			var fVariant = fieldVariant;
			let type = fieldVariant.VariantType as SpecializedGenericType;
			let genericType = type.GetGenericArg(0);

			if (TypeChecker.IsTypeList(genericType))
			{
				var object = fVariant.Get<Object>();
				var list = (List<Object>*)&object;

				for (var item in *list)
				{
					Variant variant = Variant.CreateFromBoxed(item);
					let array = scope JSONArray();

					if (SerializeArray(variant, array) case .Err)
					{
						return .Err;
					}

					dest.Add<JSONArray>(array);
				}
			}
			else if (TypeChecker.IsUserObject(genericType))
			{
				var object = fVariant.Get<Object>();
				var list = (List<Object>*)&object;

				if (genericType.IsObject)
				{
					if (SerializeListObject(list, genericType, dest) case .Err)
					{
						return .Err;
					}
				}
				else if (genericType.IsStruct)
				{
					if (SerializeListStruct(list, genericType, dest) case .Err)
					{
						return .Err;
					}
				}	
			}
			else if (TypeChecker.IsPrimitive(genericType))
			{
				if (SerializePrimitive(fieldVariant, dest) case .Err)
				{
					return .Err;
				}
			}
			return .Ok;
		}

		private static Result<void> SerializeListObject(List<Object>* list, Type type, JSONArray dest)
		{
			for (var item in *list)
			{
				Variant variant = Variant.CreateFromBoxed(item);

				let obj = scope JSONObject();

				if (SerializeObject(variant, obj) case .Err)
				{
					return .Err;
				}

				dest.Add<JSONObject>(obj);
			}

			return .Ok;
		}

		private static Result<void> SerializeListStruct(List<Object>* list, Type type, JSONArray dest)
		{
			for (var item in *list)
			{
				Variant variant = Variant.CreateReference(type, &item);

				let obj = scope JSONObject();

				if (SerializeObject(variant, obj) case .Err)
				{
					return .Err;
				}

				dest.Add<JSONObject>(obj);
			}

			return .Ok;
		}

		private static Result<void> SerializeList(List<void*>* list, Type type, JSONArray dest)
		{
			for (var item in *list)
			{
				Variant variant = Variant.CreateReference(type, item);
				let obj = scope JSONObject();

				if (SerializeObject(variant, obj) case .Err)
				{
					return .Err;
				}

				dest.Add<JSONObject>(obj);
			}

			return .Ok;
		}

		private static Result<void> SerializePrimitive(String fieldName, Variant fieldVariant, JSONObject json)
		{
			switch (fieldVariant.VariantType)
			{
			case typeof(String):
				json.Add<String>(fieldName, (String)fieldVariant.Get<String>());
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

			return .Ok;
		}

		private static Result<void> SerializePrimitive(Variant variant, JSONArray jsonArray)
		{
			var object = variant.Get<Object>();

			switch (variant.VariantType)
			{
			case typeof(String):
				jsonArray.AddRange<String>(object);
			case typeof(int):
				jsonArray.AddRange<int>(object);
			case typeof(int8):
				jsonArray.AddRange<int8>(object);
			case typeof(int16):
				jsonArray.AddRange<int16>(object);
			case typeof(int32):
				jsonArray.AddRange<int32>(object);
			case typeof(int64):
				jsonArray.AddRange<int64>(object);
			case typeof(uint):
				jsonArray.AddRange<uint>(object);
			case typeof(uint8):
				jsonArray.AddRange<uint8>(object);
			case typeof(uint16):
				jsonArray.AddRange<uint16>(object);
			case typeof(uint32):
				jsonArray.AddRange<uint32>(object);
			case typeof(uint64):
				jsonArray.AddRange<uint64>(object);
			case typeof(char8):
				jsonArray.AddRange<char8>(object);
			case typeof(char16):
				jsonArray.AddRange<char16>(object);
			case typeof(char32):
				jsonArray.AddRange<char32>(object);
			case typeof(float):
				jsonArray.AddRange<float>(object);
			case typeof(double):
				jsonArray.AddRange<double>(object);
			case typeof(bool):
				jsonArray.AddRange<bool>(object);
			default:
				return .Err;
			}

			return .Ok;
		}
	}
}
