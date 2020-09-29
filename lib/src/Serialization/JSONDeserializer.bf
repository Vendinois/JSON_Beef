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
			CANNOT_ASSIGN_LIST_TO_OBJECT,
			CANNOT_INSTANTIATE_OBJECT_FIELDS,
			ERROR_DESERIALIZATION
		}

		public static Result<void, DESERIALIZE_ERRORS> Deserialize<T>(String jsonString, T object) where T: class
		{
			return Deserialize(jsonString, object, typeof(T));
		}

		public static Result<void, DESERIALIZE_ERRORS> Deserialize<T>(String jsonString, ref T object) where T: struct where T: new
		{
			var obj = scope Object();
			obj = object;
			let res = Deserialize(jsonString, obj, typeof(T));

			switch (res)
			{
			case .Err(let err):
				return .Err(err);
			case .Ok(let val):
				object = (T)obj;
				return .Ok;
			}
		}

		private static Result<void, DESERIALIZE_ERRORS> Deserialize(String jsonString, Object object, Type type)
		{
			if (!JSONValidator.IsValidJson(jsonString))
			{
				return .Err(.INVALID_JSON);
			}

			if (object == null)
			{
				return .Err(.OBJECT_IS_NULL);
			}

			switch (JSONParser.GetJsonType(jsonString))
			{
			case .OBJECT:
				var jsonObject = scope JSONObject();
				JSONParser.ParseObject(jsonString, ref jsonObject);

				if (!AreTypeMatching(jsonObject, object))
				{
					return .Err(.JSON_NOT_MATCHING_OBJECT);
				}

				return DeserializeObject(jsonObject, object);
			case .ARRAY:
				var jsonArray = scope JSONArray();
				JSONParser.ParseArray(jsonString, ref jsonArray);

				return DeserializeArray(jsonArray, object);
			case .UNKNOWN:
				return .Err(.INVALID_JSON);
			}
		}

		private static Result<void> InitObject(Object obj)
		{
			let type = obj.GetType() as TypeInstance;
			let fields = type.GetFields();

			for (var field in fields)
			{
				if (field.FieldType.IsObject && (field.GetValue(obj) case .Ok(var variant)))
				{
					if (variant.HasValue)
					{
						InitObject(variant.Get<Object>());
						continue;
					}

					// I need to make this a specific case as the CreateObject method do not find the
					// default parameterless constructor. Maybe it comes from the configuration of the
					// reflection system in JSON_Beef's configuration.
					var valueRes = Result<Object>();
					if (typeof(String) == field.FieldType)
					{
						valueRes = .Ok(new String());
					}
					else
					{
						valueRes = field.FieldType.CreateObject();
					}

					if (valueRes != .Err)
					{
					 	field.SetValue(obj, valueRes.Value);
					}
					else
					{
						return .Err;
					}
				}
			}

			return .Ok;
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
					var innerJsonArray = scope JSONArray();
					Try!(jsonArray.Get<JSONArray>(i, ref innerJsonArray));

					Try!(DeserializeArray(innerJsonArray, innerList));

					if (addMethod.Invoke(object, innerList) case .Err)
					{
						return .Err(.CANNOT_ASSIGN_VALUE);
					}
					continue;
				}

				if (TypeChecker.IsUserObject(paramType) && (paramType.CreateObject() case .Ok(let innerObject)))
				{
					var jsonObject = scope JSONObject();
					Try!(jsonArray.Get<JSONObject>(i, ref jsonObject));

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
				int dest = default;
				if (jsonArray.Get<int>(i, ref dest) case .Err(let err))
				{
					return .Err(.ERROR_PARSING);
				}

				addMethod.Invoke(obj, dest);
			case typeof(int8):
				int8 dest = default;
				if (jsonArray.Get<int8>(i, ref dest) case .Err(let err))
				{
					return .Err(.ERROR_PARSING);
				}

				addMethod.Invoke(obj, dest);
			case typeof(int16):
				int16 dest = default;
				if (jsonArray.Get<int16>(i, ref dest) case .Err(let err))
				{
					return .Err(.ERROR_PARSING);
				}

				addMethod.Invoke(obj, dest);
			case typeof(int32):
				int32 dest = default;
				if (jsonArray.Get<int32>(i, ref dest) case .Err(let err))
				{
					return .Err(.ERROR_PARSING);
				}

				addMethod.Invoke(obj, dest);
			case typeof(int64):
				int64 dest = default;
				if (jsonArray.Get<int64>(i, ref dest) case .Err(let err))
				{
					return .Err(.ERROR_PARSING);
				}

				addMethod.Invoke(obj, dest);
			case typeof(uint):
				uint dest = default;
				if (jsonArray.Get<uint>(i, ref dest) case .Err(let err))
				{
					return .Err(.ERROR_PARSING);
				}

				addMethod.Invoke(obj, dest);
			case typeof(uint8):
				uint8 dest = default;
				if (jsonArray.Get<uint8>(i, ref dest) case .Err(let err))
				{
					return .Err(.ERROR_PARSING);
				}

				addMethod.Invoke(obj, dest);
			case typeof(uint16):
				uint16 dest = default;
				if (jsonArray.Get<uint16>(i, ref dest) case .Err(let err))
				{
					return .Err(.ERROR_PARSING);
				}

				addMethod.Invoke(obj, dest);
			case typeof(uint32):
				uint32 dest = default;
				if (jsonArray.Get<uint32>(i, ref dest) case .Err(let err))
				{
					return .Err(.ERROR_PARSING);
				}

				addMethod.Invoke(obj, dest);
			case typeof(uint64):
				uint32 dest = default;
				if (jsonArray.Get<uint32>(i, ref dest) case .Err(let err))
				{
					return .Err(.ERROR_PARSING);
				}

				addMethod.Invoke(obj, dest);
			case typeof(char8):
				char8 dest = default;
				if (jsonArray.Get<char8>(i, ref dest) case .Err(let err))
				{
					return .Err(.ERROR_PARSING);
				}

				addMethod.Invoke(obj, dest);
			case typeof(char16):
				char16 dest = default;
				if (jsonArray.Get<char16>(i, ref dest) case .Err(let err))
				{
					return .Err(.ERROR_PARSING);
				}

				addMethod.Invoke(obj, dest);
			case typeof(char32):
				char32 dest = default;
				if (jsonArray.Get<char32>(i, ref dest) case .Err(let err))
				{
					return .Err(.ERROR_PARSING);
				}

				addMethod.Invoke(obj, dest);
			case typeof(float):
				float dest = default;
				if (jsonArray.Get<float>(i, ref dest) case .Err(let err))
				{
					return .Err(.ERROR_PARSING);
				}

				addMethod.Invoke(obj, dest);
			case typeof(double):
				double dest = default;
				if (jsonArray.Get<double>(i, ref dest) case .Err(let err))
				{
					return .Err(.ERROR_PARSING);
				}

				addMethod.Invoke(obj, dest);
			case typeof(bool):
				bool dest = default;
				if (jsonArray.Get<bool>(i, ref dest) case .Err(let err))
				{
					return .Err(.ERROR_PARSING);
				}

				addMethod.Invoke(obj, dest);
			case typeof(String):
				String dest = default;
				if (jsonArray.Get<String>(i, ref dest) case .Err(let err))
				{
					return .Err(.ERROR_PARSING);
				}

				addMethod.Invoke(obj, new String(dest));
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
			let fieldType = field.FieldType;

			// null values are accepted as valid.
			var hasField = true;
			if (fieldType.IsPrimitive)
			{
				switch (fieldType)
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
			else if (fieldType.IsObject)
			{
				switch (fieldType)
				{
				case typeof(String):
					hasField = jsonObj.Contains<String>(fieldName);
				default:
					if (TypeChecker.IsTypeList(fieldType))
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

			var tempObj = obj;
			if (FieldHelper.HasFlag(field, .Static))
			{
				tempObj = null;
			}

			switch (type)
			{
			case typeof(int):
				int dest = default;
				if (jsonObj.Get<int>(key, ref dest) case .Err(let err))
				{
					 return .Err(.ERROR_PARSING);
				}

				field.SetValue(tempObj, dest);
			case typeof(int8):
				int8 dest = default;
				if (jsonObj.Get<int8>(key, ref dest) case .Err(let err))
				{
					 return .Err(.ERROR_PARSING);
				}

				field.SetValue(tempObj, dest);
			case typeof(int16):
				int16 dest = default;
				if (jsonObj.Get<int16>(key, ref dest) case .Err(let err))
				{
					 return .Err(.ERROR_PARSING);
				}

				field.SetValue(tempObj, dest);
			case typeof(int32):
				int32 dest = default;
				if (jsonObj.Get<int32>(key, ref dest) case .Err(let err))
				{
					 return .Err(.ERROR_PARSING);
				}

				field.SetValue(tempObj, dest);
			case typeof(int64):
				int64 dest = default;
				if (jsonObj.Get<int64>(key, ref dest) case .Err(let err))
				{
					 return .Err(.ERROR_PARSING);
				}

				field.SetValue(tempObj, dest);
			case typeof(uint):
				uint dest = default;
				if (jsonObj.Get<uint>(key, ref dest) case .Err(let err))
				{
					 return .Err(.ERROR_PARSING);
				}

				field.SetValue(tempObj, dest);
			case typeof(uint8):
				uint8 dest = default;
				if (jsonObj.Get<uint8>(key, ref dest) case .Err(let err))
				{
					 return .Err(.ERROR_PARSING);
				}

				field.SetValue(tempObj, dest);
			case typeof(uint16):
				uint16 dest = default;
				if (jsonObj.Get<uint16>(key, ref dest) case .Err(let err))
				{
					 return .Err(.ERROR_PARSING);
				}

				field.SetValue(tempObj, dest);
			case typeof(uint32):
				uint32 dest = default;
				if (jsonObj.Get<uint32>(key, ref dest) case .Err(let err))
				{
					 return .Err(.ERROR_PARSING);
				}

				field.SetValue(tempObj, dest);
			case typeof(uint64):
				uint64 dest = default;
				if (jsonObj.Get<uint64>(key, ref dest) case .Err(let err))
				{
					 return .Err(.ERROR_PARSING);
				}

				field.SetValue(tempObj, dest);
			case typeof(char8):
				char8 dest = default;
				if (jsonObj.Get<char8>(key, ref dest) case .Err(let err))
				{
					 return .Err(.ERROR_PARSING);
				}

				field.SetValue(tempObj, dest);
			case typeof(char16):
				char16 dest = default;
				if (jsonObj.Get<char16>(key, ref dest) case .Err(let err))
				{
					 return .Err(.ERROR_PARSING);
				}

				field.SetValue(tempObj, dest);
			case typeof(char32):
				char32 dest = default;
				if (jsonObj.Get<char32>(key, ref dest) case .Err(let err))
				{
					 return .Err(.ERROR_PARSING);
				}

				field.SetValue(tempObj, dest);
			case typeof(float):
				float dest = default;
				if (jsonObj.Get<float>(key, ref dest) case .Err(let err))
				{
					 return .Err(.ERROR_PARSING);
				}

				field.SetValue(tempObj, dest);
			case typeof(double):
				double dest = default;
				if (jsonObj.Get<double>(key, ref dest) case .Err(let err))
				{
					 return .Err(.ERROR_PARSING);
				}

				field.SetValue(tempObj, dest);
			case typeof(bool):
				bool dest = default;
				if (jsonObj.Get<bool>(key, ref dest) case .Err(let err))
				{
					 return .Err(.ERROR_PARSING);
				}

				field.SetValue(tempObj, dest);
			case typeof(String):
				var dest = scope String();
				if (jsonObj.Get<String>(key, ref dest) case .Err(let err))
				{
					return .Err(.ERROR_PARSING);
				}

				var str = new String(dest);
				var fieldVariant = field.GetValue(tempObj).Value;

				if (fieldVariant.HasValue)
				{
					// We need to delete the existing field otherwise it creates a memory leak.
					delete fieldVariant.Get<Object>();
				}

				field.SetValue(tempObj, str);
			default:
				return .Err(.ERROR_PARSING);
			}

			return .Ok;
		}

		private static Result<void, DESERIALIZE_ERRORS> SetObjectField(FieldInfo field, JSONObject jsonObject, Object obj)
		{
			let key = scope String(field.Name);

			var tempObj = obj;
			if (FieldHelper.HasFlag(field, .Static))
			{
				tempObj = null;
			}

			var dest = scope JSONObject();
			if (jsonObject.Get<JSONObject>(key, ref dest) case .Err(let err))
			{
				return .Err(.ERROR_PARSING);
			}

			if (dest == null)
			{
				field.SetValue(tempObj, null);
				return .Ok;
			}

			var fieldVariant = field.GetValue(tempObj).Value;
			if (fieldVariant.HasValue)
			{
				delete fieldVariant.Get<Object>();
			}

			var fieldObject = field.FieldType.CreateObject().Value;
			Try!(DeserializeObject(dest, fieldObject));
			field.SetValue(tempObj, fieldObject);

			return .Ok;
		}

		private static Result<void, DESERIALIZE_ERRORS> SetArrayField(FieldInfo field, JSONObject jsonObject, Object obj)
		{
			let key = scope String(field.Name);

			var tempObj = obj;
			if (FieldHelper.HasFlag(field, .Static))
			{
				tempObj = null;
			}

			var dest = scope JSONArray();
			if (jsonObject.Get<JSONArray>(key, ref dest) case .Err(let err))
			{
				return .Err(.ERROR_PARSING);
			}

			if (dest == null)
			{
				field.SetValue(tempObj, null);
				return .Ok;
			}

			var fieldVariant = field.GetValue(tempObj).Value;
			if (fieldVariant.HasValue)
			{
				delete fieldVariant.Get<Object>();
			}

			var fieldList = field.FieldType.CreateObject().Value;
			Try!(DeserializeArray(dest, fieldList));
			field.SetValue(tempObj, fieldList);

			return .Ok;
		}
	}
}
