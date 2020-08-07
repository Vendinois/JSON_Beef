using System;
using System.Collections;
using System.Reflection;
using JSON_Beef.Types;
using JSON_Beef.Util;

namespace JSON_Beef.Serialization
{
	public static class JSONDeserializer
	{
		public enum DESERIALIZE_ERRORS
		{
			JSON_NOT_MATCHING_OBJECT,
			ERROR_PARSING,
			CANNOT_ASSIGN_VALUE,
			FIELD_NOT_FOUND,
			INVALID_FIELD_TYPE,
			INVALID_JSON,
			OBJECT_IS_NULL,
			CANNOT_ASSIGN_LIST_TO_OBJECT
		}

		public static Result<void, DESERIALIZE_ERRORS> Deserialize<T>(String jsonString, T object)
		{
			if (!JSONValidator.IsValidJson(jsonString))
			{
				return .Err(.INVALID_JSON);
			}

			if (object == null)
			{
				return .Err(.OBJECT_IS_NULL);
			}

			let doc = scope JSONDocument();

			switch (doc.GetJsonType(jsonString))
			{
			case .OBJECT:
				var jsonObject = scope JSONObject();
				doc.ParseObject(jsonString, ref jsonObject);

				if (!AreTypeMatching(jsonObject, object))
				{
					return .Err(.JSON_NOT_MATCHING_OBJECT);
				}

				return DeserializeObject(jsonObject, object);
			case .ARRAY:
				var jsonArray = scope JSONArray();
				doc.ParseArray(jsonString, ref jsonArray);

				return DeserializeArray(jsonArray, object);
			case .UNKNOWN:
				return .Err(.INVALID_JSON);
			}
		}

		// The object corresponds to the jsonObject
		// e.g.: jsonArray => {"Key": "Value"} -- object => CustomObject
		private static Result<void, DESERIALIZE_ERRORS> DeserializeObject(JSONObject jsonObject, Object object)
		{
			if (object == null)
			{
				return .Err(.ERROR_PARSING);
			}

			Try!(DeserializeBaseObject(jsonObject, object));

			let type = object.GetType() as TypeInstance;
			let fields = type.GetFields();

			for (var field in fields)
			{
				if (AttributeChecker.ShouldIgnore(field))
				{
					continue;
				}

				if (TypeChecker.IsTypeList(field.FieldType))
				{
					Try!(SetArrayField(field, jsonObject, object));
				}
				else if (TypeChecker.IsUserObject(field.FieldType))
				{
					Try!(SetObjectField(field, jsonObject, object));
				}
				else if (TypeChecker.IsPrimitive(field.FieldType))
				{
					Try!(SetPrimitiveField(field, jsonObject, object));
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			}

			return .Ok;
		}

		private static Result<void, DESERIALIZE_ERRORS> DeserializeBaseObject(JSONObject jsonObject, Object obj)
		{
			let type = obj.GetType();
			let baseType = type.BaseType;

			if (baseType == type)
			{
				return .Ok;
			}

			let fields = baseType.GetFields();

			for (var field in fields)
			{
				if (AttributeChecker.ShouldIgnore(field))
				{
					continue;
				}

				if (TypeChecker.IsTypeList(field.FieldType))
				{
					Try!(SetArrayField(field, jsonObject, obj));
				}
				else if (TypeChecker.IsUserObject(field.FieldType))
				{
					Try!(SetObjectField(field, jsonObject, obj));
				}
				else if (TypeChecker.IsPrimitive(field.FieldType))
				{
					Try!(SetPrimitiveField(field, jsonObject, obj));
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			}
			return .Ok;
		}

		// The object corresponds to the jsonArray
		// e.g.: jsonArray => [["1", "2", "3"], ["1", "2"]] -- object => List<List<String>>
		// e.g.: jsonArray => ["1", "2", "3"] -- object => List<String>
		// e.g.: jsonArray => [{"Key": "Value"}] -- object => List<CustomObject>
		private static Result<void, DESERIALIZE_ERRORS> DeserializeArray(JSONArray jsonArray, Object object)
		{
			if (!TypeChecker.IsTypeList(object))
			{
				return .Err(.CANNOT_ASSIGN_LIST_TO_OBJECT);
			}

			let type = object.GetType() as SpecializedGenericType;
			let addMethod = Try!(type.GetMethod("Add"));
			let paramType = type.GetGenericArg(0) as TypeInstance;

			for (int i = 0; i < jsonArray.Count; i++)
			{
				// Calls recursively for handling List<List<...>>
				if (TypeChecker.IsTypeList(paramType) && (paramType.CreateObject() case .Ok(let innerList)))
				{
					let innerJsonArray = Try!(jsonArray.Get<JSONArray>(i));

					Try!(DeserializeArray(innerJsonArray, innerList));

					if (addMethod.Invoke(object, innerList) case .Err)
					{
						return .Err(.CANNOT_ASSIGN_VALUE);
					}
					continue;
				}

				if (TypeChecker.IsUserObject(paramType) && (paramType.CreateObject() case .Ok(let innerObject)))
				{
					let jsonObject = Try!(jsonArray.Get<JSONObject>(i));

					Try!(DeserializeObject(jsonObject, innerObject));

					if (addMethod.Invoke(object, innerObject) case .Err)
					{
						return .Err(.CANNOT_ASSIGN_VALUE);
					}
					continue;
				}

				if (TypeChecker.IsPrimitive(paramType))
				{
					Try!(AddPrimitiveToArray(paramType, jsonArray, i, object, addMethod));
				}
			}

			return .Ok;
		}

		private static Result<void, DESERIALIZE_ERRORS> AddPrimitiveToArray(Type type, JSONArray jsonArray, int i, Object obj, MethodInfo addMethod)
		{
			switch (type)
			{
			case typeof(int):
				if (jsonArray.Get<int>(i) case .Ok(let val))
				{
					addMethod.Invoke(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(int8):
				if (jsonArray.Get<int8>(i) case .Ok(let val))
				{
					addMethod.Invoke(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(int16):
				if (jsonArray.Get<int16>(i) case .Ok(let val))
				{
					addMethod.Invoke(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(int32):
				if (jsonArray.Get<int32>(i) case .Ok(let val))
				{
					addMethod.Invoke(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(int64):
				if (jsonArray.Get<int64>(i) case .Ok(let val))
				{
					addMethod.Invoke(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(uint):
				if (jsonArray.Get<uint>(i) case .Ok(let val))
				{
					addMethod.Invoke(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(uint8):
				if (jsonArray.Get<uint8>(i) case .Ok(let val))
				{
					addMethod.Invoke(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(uint16):
				if (jsonArray.Get<uint16>(i) case .Ok(let val))
				{
					addMethod.Invoke(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(uint32):
				if (jsonArray.Get<uint32>(i) case .Ok(let val))
				{
					addMethod.Invoke(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(uint64):
				if (jsonArray.Get<uint64>(i) case .Ok(let val))
				{
					addMethod.Invoke(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(char8):
				if (jsonArray.Get<char8>(i) case .Ok(let val))
				{
					addMethod.Invoke(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(char16):
				if (jsonArray.Get<char16>(i) case .Ok(let val))
				{
					addMethod.Invoke(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(char32):
				if (jsonArray.Get<char32>(i) case .Ok(let val))
				{
					addMethod.Invoke(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(float):
				if (jsonArray.Get<float>(i) case .Ok(let val))
				{
					addMethod.Invoke(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(double):
				if (jsonArray.Get<double>(i) case .Ok(let val))
				{
					addMethod.Invoke(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(bool):
				if (jsonArray.Get<bool>(i) case .Ok(let val))
				{
					addMethod.Invoke(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(String):
				if (jsonArray.Get<String>(i) case .Ok(let val))
				{
					addMethod.Invoke(obj, new String(val));
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			}

			return .Ok;
		}

		private static bool AreTypeMatching(JSONObject jsonObject, Object obj)
		{
			let type = obj.GetType();
			let fields = type.GetFields();

			if (!AreBaseTypeMatching(jsonObject, obj))
			{
				return false;
			}

			for (var field in fields)
			{
				if (AttributeChecker.ShouldIgnore(field))
				{
					continue;
				}

				if (!HasField(jsonObject, obj, field))
				{
					return false;
				}
			}
			return true;
		}

		private static bool AreBaseTypeMatching(JSONObject jsonObject, Object obj)
		{
			let type = obj.GetType();
			let baseType = type.BaseType;

			if (type == baseType)
			{
				return true;
			}

			let fields = baseType.GetFields();

			for (var field in fields)
			{
				if (AttributeChecker.ShouldIgnore(field))
				{
					continue;
				}

				let fieldValue = field.GetValue(obj).Get().Get<Object>();

				if (!HasField(jsonObject, obj, field))
				{
					return false;
				}

				if (!AreBaseTypeMatching(jsonObject, fieldValue))
				{
					return false;
				}
			}

			return true;
		}

		private static bool HasField(JSONObject jsonObj, Object obj, FieldInfo field)
		{
			let fieldName = scope String(field.Name);
			let fieldVariant = field.GetValue(obj).Value;
			let fieldVariantType = fieldVariant.VariantType;

			var hasField = false;
			if (fieldVariantType.IsPrimitive)
			{
				switch (fieldVariantType)
				{
				case typeof(int):
					hasField = jsonObj.Contains<int>(fieldName);
				case typeof(int8):
					hasField = jsonObj.Contains<int8>(fieldName);
				case typeof(int16):
					hasField = jsonObj.Contains<int16>(fieldName);
				case typeof(int32):
					hasField = jsonObj.Contains<int32>(fieldName);
				case typeof(int64):
					hasField = jsonObj.Contains<int64>(fieldName);
				case typeof(uint):
					hasField = jsonObj.Contains<uint>(fieldName);
				case typeof(uint8):
					hasField = jsonObj.Contains<uint8>(fieldName);
				case typeof(uint16):
					hasField = jsonObj.Contains<uint16>(fieldName);
				case typeof(uint32):
					hasField = jsonObj.Contains<uint32>(fieldName);
				case typeof(uint64):
					hasField = jsonObj.Contains<uint64>(fieldName);
				case typeof(char8):
					hasField = jsonObj.Contains<char8>(fieldName);
				case typeof(char16):
					hasField = jsonObj.Contains<char16>(fieldName);
				case typeof(char32):
					hasField = jsonObj.Contains<char32>(fieldName);
				case typeof(bool):
					hasField = jsonObj.Contains<bool>(fieldName);
				case typeof(float):
					hasField = jsonObj.Contains<float>(fieldName);
				case typeof(double):
					hasField = jsonObj.Contains<double>(fieldName);
				default:
					return false;
				}
			}
			else if (fieldVariantType.IsObject)
			{
				switch (fieldVariantType)
				{
				case typeof(String):
					hasField = jsonObj.Contains<String>(fieldName);
				default:
					let fieldValue = fieldVariant.Get<Object>();

					if (TypeChecker.IsTypeList(fieldValue))
					{
						hasField = jsonObj.Contains<JSONArray>(fieldName);
					}
					else
					{
						hasField = jsonObj.Contains<JSONObject>(fieldName);
					}
				}
			}

			return hasField;
		}

		static Result<void, DESERIALIZE_ERRORS> SetPrimitiveField(FieldInfo field, JSONObject jsonObj, Object obj)
		{
			let type = field.FieldType;
			let key = scope String(field.Name);

			switch (type)
			{
			case typeof(int):
				if (jsonObj.Get<int>(key) case .Ok(let val))
				{
					 field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(int8):
				if (jsonObj.Get<int8>(key) case .Ok(let val))
				{
					 field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(int16):
				if (jsonObj.Get<int16>(key) case .Ok(let val))
				{
					 field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(int32):
				if (jsonObj.Get<int32>(key) case .Ok(let val))
				{
					 field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(int64):
				if (jsonObj.Get<int64>(key) case .Ok(let val))
				{
					 field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(uint):
				if (jsonObj.Get<uint>(key) case .Ok(let val))
				{
					 field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(uint8):
				if (jsonObj.Get<uint8>(key) case .Ok(let val))
				{
					 field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(uint16):
				if (jsonObj.Get<uint16>(key) case .Ok(let val))
				{
					 field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(uint32):
				if (jsonObj.Get<uint32>(key) case .Ok(let val))
				{
					 field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(uint64):
				if (jsonObj.Get<uint64>(key) case .Ok(let val))
				{
					 field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(char8):
				if (jsonObj.Get<char8>(key) case .Ok(let val))
				{
					 field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(char16):
				if (jsonObj.Get<char16>(key) case .Ok(let val))
				{
					 field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(char32):
				if (jsonObj.Get<char32>(key) case .Ok(let val))
				{
					 field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(float):
				if (jsonObj.Get<float>(key) case .Ok(let val))
				{
					 field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(double):
				if (jsonObj.Get<double>(key) case .Ok(let val))
				{
					 field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(bool):
				if (jsonObj.Get<bool>(key) case .Ok(let val))
				{
					 field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(String):
				if (jsonObj.Get<String>(key) case .Ok(let val))
				{
					field.SetValue(obj, new String(val));
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			default:
				return .Err(.ERROR_PARSING);
			}

			return .Ok;
		}

		private static Result<void, DESERIALIZE_ERRORS> SetObjectField(FieldInfo field, JSONObject jsonObject, Object obj)
		{
			let type = field.FieldType;
			let key = scope String(field.Name);

			if ((type.CreateObject() case .Ok(let fieldObject)) &&
				(jsonObject.Get<JSONObject>(key) case .Ok(let val)))
			{
				if (val == null)
				{
					field.SetValue(obj, null);
					return .Ok;
				}

				Try!(DeserializeObject(val, fieldObject));
				field.SetValue(obj, fieldObject);
			}
			else
			{
				return .Err(.ERROR_PARSING);
			}

			return .Ok;
		}

		private static Result<void, DESERIALIZE_ERRORS> SetArrayField(FieldInfo field, JSONObject jsonObject, Object obj)
		{
			let type = field.FieldType;
			let key = scope String(field.Name);

			if ((type.CreateObject() case .Ok(let fieldList)) &&
				(jsonObject.Get<JSONArray>(key) case .Ok(let array)))
			{
				if (array == null)
				{
					field.SetValue(obj, null);
					return .Ok;
				}

				Try!(DeserializeArray(array, fieldList));
				field.SetValue(obj, fieldList);
			}
			else
			{
				return .Err(.ERROR_PARSING);
			}

			return .Ok;
		}
	}
}
