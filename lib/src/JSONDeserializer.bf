using System;
using System.Collections;
using System.Reflection;
using JSON_Beef;

namespace JSON_Beef
{
	public class JSONDeserializer
	{
		public enum DESERIALIZE_ERRORS
		{
			NO_ERROR,
			TYPE_NOT_MATCHING,
			ERROR_PARSING,
			CANNOT_ASSIGN_VALUE,
			FIELD_NOT_FOUND,
			INVALID_FIELD_TYPE
		}

		public static Result<T, DESERIALIZE_ERRORS> Deserialize<T>(String json) where T: new, delete
		{
			if (!JSONValidator.IsValidJson(json))
			{
				return .Err(.ERROR_PARSING);
			}

			var finalObj = new T();
			let doc = scope JSONDocument();
			let docType = doc.GetJsonType(json);

			var res = Result<void, DESERIALIZE_ERRORS>();
			switch (docType)
			{
			case .ARRAY:
				res = DeserializeArrayInternal(json, finalObj);
			case .OBJECT:
				res = DeserializeObjectInternal(json, finalObj);
			case .UNKNOWN:
				delete finalObj;
				return .Err(.ERROR_PARSING);
			}

			switch (res)
			{
			case .Err(let err):
				delete finalObj;
				return .Err(err);
			case .Ok:
				return .Ok(finalObj);
			}
		}

		private static Result<void, DESERIALIZE_ERRORS> DeserializeObjectInternal(String json, Object obj)
		{
			let doc = scope JSONDocument();
			let res = doc.ParseObject(json);

			switch (res)
			{
			case .Err(let err):
				delete res.Value;
				return .Err(.ERROR_PARSING);
			default:
				break;
			}

			let jsonObj = res.Value;
			let typeMatched = AreTypeMatching(jsonObj, obj);

			if (typeMatched != .Ok(.NO_ERROR))
			{
				delete jsonObj;
				return .Err(typeMatched);
			}

			let finalRes = DeserializeObjectInternal(jsonObj, obj);

			delete jsonObj;

			switch (finalRes)
			{
			case .Err(let err):
				return .Err(.ERROR_PARSING);
			default:
				return .Ok;
			}
		}

		private static Result<void, DESERIALIZE_ERRORS> DeserializeObjectInternal(JSONObject jsonObj, Object obj)
		{
			let type = obj.GetType();
			let fields = type.GetFields();

			let res = DeserializeBaseObjectInternal(jsonObj, obj);

			switch (res)
			{
			case .Err(let err):
				return .Err(err);
			case .Ok:
				break;
			}

			for (var field in fields)
			{
				if (ShouldIgnore(field))
				{
					continue;
				}

				let ret = ParseField(jsonObj, obj, field);

				switch (ret)
				{
				case .Err(let err):
					return ret;
				case .Ok:
					 continue;
				}
			}
			return .Ok;
		}

		private static Result<void, DESERIALIZE_ERRORS> DeserializeBaseObjectInternal(JSONObject jsonObj, Object obj)
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
				if (ShouldIgnore(field))
				{
					continue;
				}

				let res = ParseField(jsonObj, obj, field);

				switch (res)
				{
				case .Err(let err):
					return res;
				case .Ok:
					 continue;
				}
			}

			return .Ok;
		}

		private static Result<void, DESERIALIZE_ERRORS> ParseField(JSONObject jsonObj, Object obj, FieldInfo field)
		{
			let fieldName = scope String(field.Name);
			let fieldType = field.FieldType;

			var valueSet = Result<void, FieldInfo.Error>();

			if (fieldType.IsPrimitive && (SetPrimitiveField(field, obj, jsonObj) case .Err(let err)))
			{
				return .Err(err);
			}
			else if (fieldType.IsObject)
			{
				if (IsList(fieldType) && (SetListField(field, obj, jsonObj) case .Ok))
				{
					return .Ok;
				}
				else
				{
					switch (fieldType)
					{
					case typeof(String):
						if (jsonObj.Get<String>(fieldName) case .Ok(let val))
						{
							valueSet = field.SetValue(obj, new String(val));
						}
						else
						{
							return .Err(.ERROR_PARSING);
						}
					default:
						let innerObj = fieldType.CreateObject().Get();
						let innerJsonObjRes = jsonObj.Get<JSONObject>(fieldName);

						switch (innerJsonObjRes)
						{
						case .Ok(let val):
							if (val == null)
							{
								valueSet = field.SetValue(obj, null);
								break;
							}

							if (DeserializeObjectInternal(val, innerObj) case .Ok)
							{
								valueSet = field.SetValue(obj, innerObj);	
							}
							else
							{
								return .Err(.ERROR_PARSING);
							}
						case .Err:
							return .Err(.ERROR_PARSING);
						}
					}
				}
			}

			switch (valueSet)
			{
			case .Err(let err):
				return .Err(.CANNOT_ASSIGN_VALUE);
			case .Ok:
				return .Ok;
			}
		}

		private static Result<void, DESERIALIZE_ERRORS> DeserializeArrayInternal(String json, Object obj)
		{
			return .Ok;
		}

		private static Result<void, DESERIALIZE_ERRORS> DeserializeArrayInternal(JSONObject json, Object obj)
		{
			return .Ok;
		}

		private static Result<void, DESERIALIZE_ERRORS> DeserializeArrayInternal(JSONArray json, Object obj)
		{
			return .Ok;
		}

		private static Result<DESERIALIZE_ERRORS> AreTypeMatching(JSONObject jsonObj, Object obj)
		{
			let type = obj.GetType();
			let fields = type.GetFields();

			let baseTypeMatching = AreBaseTypeMatching(jsonObj, obj);
			if (baseTypeMatching != .Ok(.NO_ERROR))
			{
				return baseTypeMatching;
			}

			for (var field in fields)
			{
				if (ShouldIgnore(field))
				{
					continue;
				}

				let hasField = HasField(jsonObj, obj, field);
				if (hasField != .Ok(.NO_ERROR))
				{
					return hasField;
				}
			}
			return .Ok(.NO_ERROR);
		}

		private static Result<DESERIALIZE_ERRORS> AreBaseTypeMatching(JSONObject jsonObj, Object obj)
		{
			let type = obj.GetType();
			let baseType = type.BaseType;

			if (type == baseType)
			{
				return .Ok(.NO_ERROR);
			}

			let fields = baseType.GetFields();

			for (var field in fields)
			{
				if (ShouldIgnore(field))
				{
					continue;
				}

				let fieldValue = field.GetValue(obj).Get().Get<Object>();
				let hasField = HasField(jsonObj, obj, field);
				if (hasField != .Ok(.NO_ERROR))
				{
					return hasField;
				}

				let baseTypeMatching = AreBaseTypeMatching(jsonObj, fieldValue);
				if (baseTypeMatching != .Ok(.NO_ERROR))
				{
					return baseTypeMatching;
				}
			}

			return .Ok(.NO_ERROR);
		}

		private static bool ShouldIgnore(FieldInfo field)
		{
			let shouldIgnore = field.GetCustomAttribute<IgnoreSerializeAttribute>();

			return ((shouldIgnore == .Ok) || field.HasFieldFlag(.PrivateScope) || field.HasFieldFlag(.Private));
		}

		private static bool IsList(Object object)
		{
			let type = object.GetType();
			let typeName = scope String();
			type.GetName(typeName);

			return typeName.Equals("List");
		}

		private static bool IsList(Type type)
		{
			let typeName = scope String();
			type.GetName(typeName);

			return typeName.Equals("List");
		}

		private static Result<DESERIALIZE_ERRORS> HasField(JSONObject jsonObj, Object obj, FieldInfo field)
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
					return .Ok(.INVALID_FIELD_TYPE);
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

					if (IsList(fieldValue))
					{
						hasField = jsonObj.Contains<JSONArray>(fieldName);
					}
					else
					{
						hasField = jsonObj.Contains<JSONObject>(fieldName);
					}
				}
			}

			return (hasField) ? .Ok(.NO_ERROR) : .Ok(.FIELD_NOT_FOUND);
		}

		/*private static bool IsNullOrJSONObject(JSONObject jsonObj, String key)
		{
			if (jsonObj.Contains<JSON_LITERAL>(key))
			{
				let val = jsonObj.Get<JSON_LITERAL>(key);

				if (val != .Ok(.NULL))
				{
					return false;
				}
			}

			if (!jsonObj.Contains<JSONObject>(key))
			{
				return false;
			}

			return true;
		}

		private static bool IsNullOrJSONArray(JSONObject jsonObj, String key)
		{
			if (jsonObj.Contains<JSON_LITERAL>(key))
			{
				let val = jsonObj.Get<JSON_LITERAL>(key);

				if (val != .Ok(.NULL))
				{
					return false;
				}
			}

			if (!jsonObj.Contains<JSONArray>(key))
			{
				return false;
			}

			return true;
		}*/
		private static Result<void, DESERIALIZE_ERRORS> SetPrimitiveField(FieldInfo field, Object obj, JSONObject jsonObj)
		{
			let fieldName = scope String(field.Name);
			let fieldType = field.FieldType;
			var valueSet = Result<void, FieldInfo.Error>();

			switch (fieldType)
			{
			case typeof(int):
				if (jsonObj.Get<int>(fieldName) case .Ok(let val))
				{
					valueSet = field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(int8):
				if (jsonObj.Get<int8>(fieldName) case .Ok(let val))
				{
					valueSet = field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(int16):
				if (jsonObj.Get<int16>(fieldName) case .Ok(let val))
				{
					valueSet = field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(int32):
				if (jsonObj.Get<int32>(fieldName) case .Ok(let val))
				{
					valueSet = field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(int64):
				if (jsonObj.Get<int64>(fieldName) case .Ok(let val))
				{
					valueSet = field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(uint):
				if (jsonObj.Get<uint>(fieldName) case .Ok(let val))
				{
					valueSet = field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(uint8):
				if (jsonObj.Get<uint8>(fieldName) case .Ok(let val))
				{
					valueSet = field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(uint16):
				if (jsonObj.Get<uint16>(fieldName) case .Ok(let val))
				{
					valueSet = field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(uint32):
				if (jsonObj.Get<uint32>(fieldName) case .Ok(let val))
				{
					valueSet = field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(uint64):
				if (jsonObj.Get<uint64>(fieldName) case .Ok(let val))
				{
					valueSet = field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(char8):
				if (jsonObj.Get<char8>(fieldName) case .Ok(let val))
				{
					valueSet = field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(char16):
				if (jsonObj.Get<char16>(fieldName) case .Ok(let val))
				{
					valueSet = field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(char32):
				if (jsonObj.Get<char32>(fieldName) case .Ok(let val))
				{
					valueSet = field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(float):
				if (jsonObj.Get<float>(fieldName) case .Ok(let val))
				{
					valueSet = field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(double):
				if (jsonObj.Get<double>(fieldName) case .Ok(let val))
				{
					valueSet = field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			case typeof(bool):
				if (jsonObj.Get<bool>(fieldName) case .Ok(let val))
				{
					valueSet = field.SetValue(obj, val);
				}
				else
				{
					return .Err(.ERROR_PARSING);
				}
			default:
				return .Err(.ERROR_PARSING);
			}

			switch (valueSet)
			{
			case .Err(let err):
				return .Err(.CANNOT_ASSIGN_VALUE);
			case .Ok:
				return .Ok;
			}
		}

		static Result<void, DESERIALIZE_ERRORS> SetListField(FieldInfo field, Object obj, JSONObject jsonObj)
		{
			let fieldName = scope String(field.Name);
			let fieldType = field.FieldType;
			let fieldValue = field.GetValue(obj).Value.Get<Object>();

			let addMethod = fieldType.GetMethod("Add").Get();
			let paramType = addMethod.GetParamType(0);

			if (fieldValue == null)
			{
				return .Err(.CANNOT_ASSIGN_VALUE);
			}

			let jsonArrayRes = jsonObj.Get<JSONArray>(fieldName);

			if (jsonArrayRes == .Err(.INVALID_TYPE))
			{
				return .Err(.ERROR_PARSING);
			}

			let jsonArray = jsonArrayRes.Value;

			if (!fieldType.IsGenericType)
			{
				return .Err(.ERROR_PARSING);
			}

			for (int i = 0; i < jsonArray.Count; i++)
			{
				switch (paramType)
				{
				case typeof(int):
					if (jsonArray.Get<int>(i) case .Ok(let val))
					{
						addMethod.Invoke(fieldValue, val);
					}
					else
					{
						return .Err(.ERROR_PARSING);
					}
				case typeof(int8):
					if (jsonArray.Get<int8>(i) case .Ok(let val))
					{
						addMethod.Invoke(fieldValue, val);
					}
					else
					{
						return .Err(.ERROR_PARSING);
					}
				case typeof(int16):
					if (jsonArray.Get<int16>(i) case .Ok(let val))
					{
						addMethod.Invoke(fieldValue, val);
					}
					else
					{
						return .Err(.ERROR_PARSING);
					}
				case typeof(int32):
					if (jsonArray.Get<int32>(i) case .Ok(let val))
					{
						addMethod.Invoke(fieldValue, val);
					}
					else
					{
						return .Err(.ERROR_PARSING);
					}
				case typeof(int64):
					if (jsonArray.Get<int64>(i) case .Ok(let val))
					{
						addMethod.Invoke(fieldValue, val);
					}
					else
					{
						return .Err(.ERROR_PARSING);
					}
				case typeof(uint):
					if (jsonArray.Get<uint>(i) case .Ok(let val))
					{
						addMethod.Invoke(fieldValue, val);
					}
					else
					{
						return .Err(.ERROR_PARSING);
					}
				case typeof(uint8):
					if (jsonArray.Get<uint8>(i) case .Ok(let val))
					{
						addMethod.Invoke(fieldValue, val);
					}
					else
					{
						return .Err(.ERROR_PARSING);
					}
				case typeof(uint16):
					if (jsonArray.Get<uint16>(i) case .Ok(let val))
					{
						addMethod.Invoke(fieldValue, val);
					}
					else
					{
						return .Err(.ERROR_PARSING);
					}
				case typeof(uint32):
					if (jsonArray.Get<uint32>(i) case .Ok(let val))
					{
						addMethod.Invoke(fieldValue, val);
					}
					else
					{
						return .Err(.ERROR_PARSING);
					}
				case typeof(uint64):
					if (jsonArray.Get<uint64>(i) case .Ok(let val))
					{
						addMethod.Invoke(fieldValue, val);
					}
					else
					{
						return .Err(.ERROR_PARSING);
					}
				case typeof(char8):
					if (jsonArray.Get<char8>(i) case .Ok(let val))
					{
						addMethod.Invoke(fieldValue, val);
					}
					else
					{
						return .Err(.ERROR_PARSING);
					}
				case typeof(char16):
					if (jsonArray.Get<char16>(i) case .Ok(let val))
					{
						addMethod.Invoke(fieldValue, val);
					}
					else
					{
						return .Err(.ERROR_PARSING);
					}
				case typeof(char32):
					if (jsonArray.Get<char32>(i) case .Ok(let val))
					{
						addMethod.Invoke(fieldValue, val);
					}
					else
					{
						return .Err(.ERROR_PARSING);
					}
				case typeof(float):
					if (jsonArray.Get<float>(i) case .Ok(let val))
					{
						addMethod.Invoke(fieldValue, val);
					}
					else
					{
						return .Err(.ERROR_PARSING);
					}
				case typeof(double):
					if (jsonArray.Get<double>(i) case .Ok(let val))
					{
						addMethod.Invoke(fieldValue, val);
					}
					else
					{
						return .Err(.ERROR_PARSING);
					}
				case typeof(bool):
					if (jsonArray.Get<bool>(i) case .Ok(let val))
					{
						addMethod.Invoke(fieldValue, val);
					}
					else
					{
						return .Err(.ERROR_PARSING);
					}
				case typeof(String):
					if (jsonArray.Get<String>(i) case .Ok(let val))
					{
						addMethod.Invoke(fieldValue, new String(val));
					}
					else
					{
						return .Err(.ERROR_PARSING);
					}
				default:
					if (paramType.IsObject && (jsonArray.Get<JSONObject>(i) case .Ok(let val)))
					{
						let generic = fieldType as SpecializedGenericType;
						let genericType = generic.GetGenericArg(0) as TypeInstance;

						let typeName = scope String();
						genericType.GetFullName(typeName);

						var innerObjRes = genericType.CreateObject();

						if (innerObjRes == .Err)
						{
							return .Err(.CANNOT_ASSIGN_VALUE);
						}

						var innerObj = innerObjRes.Value;

						if ((DeserializeObjectInternal(val, innerObj) case .Ok) &&
							(addMethod.Invoke(fieldValue, innerObj) case .Ok))
						{
							continue;
						}
						else
						{
							return .Err(.CANNOT_ASSIGN_VALUE);
						}
					}
					else
					{
						return .Err(.ERROR_PARSING);
					}
				}
			}

			return .Ok;
		}
	}
}
