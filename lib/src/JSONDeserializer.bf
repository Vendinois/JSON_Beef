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

			switch (finalRes)
			{
			case .Err(let err):
				delete jsonObj;
				return .Err(.ERROR_PARSING);
			default:
				delete jsonObj;
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

			if (fieldType.IsPrimitive)
			{
				switch (fieldType)
				{
				case typeof(int):
					let res = jsonObj.Get<int>(fieldName);
					
					switch (res)
					{
					case .Err(let err):
						return .Err(.ERROR_PARSING);
					case .Ok(let val):
						valueSet = field.SetValue(obj, val);
					}
				case typeof(float):
					let res = jsonObj.Get<float>(fieldName);

					switch (res)
					{
					case .Err(let err):
						return .Err(.ERROR_PARSING);
					case .Ok(Object val):
						valueSet = field.SetValue(obj, val);
					}
				case typeof(bool):
					let ret = jsonObj.Get<JSON_LITERAL>(fieldName);

					switch (ret)
					{
					case .Err(let err):
						return .Err(.CANNOT_ASSIGN_VALUE);
					case .Ok(let val):
						if (val == .NULL)
						{
							return .Err(.CANNOT_ASSIGN_VALUE);
						}

						if (JSONUtil.LiteralToBool(val) case .Ok(let v))
						{
							valueSet = field.SetValue(obj, v);
						}
						else
						{
							return .Err(.CANNOT_ASSIGN_VALUE);
						}
					}
				default:
					return .Err(.ERROR_PARSING);
				}
			}
			else if (fieldType.IsObject)
			{
				if (IsList(fieldType))
				{
					let fieldValue = field.GetValue(obj).Value.Get<Object>();
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
						let variant = jsonArray.GetVariant(i);

						switch (variant.VariantType)
						{
						case typeof(String):
							let val = new String(variant.Get<String>());
							fieldType.GetMethod("Add").Get().Invoke(fieldValue, val);
						case typeof(int):
							let val = variant.Get<int>();
							fieldType.GetMethod("Add").Get().Invoke(fieldValue, val);
					  	case typeof(float):
							let val = variant.Get<float>();
							fieldType.GetMethod("Add").Get().Invoke(fieldValue, val);
						case typeof(JSON_LITERAL):
							let val = variant.Get<JSON_LITERAL>();

							if (val == .NULL)
							{
								fieldType.GetMethod("Add").Get().Invoke(fieldValue, null);
							}
							else
							{
								let b = JSONUtil.LiteralToBool(val);
								fieldType.GetMethod("Add").Get().Invoke(fieldValue, b);
							}
						case typeof(JSONArray):
							break;
						case typeof(JSONObject):
							let val = variant.Get<JSONObject>();

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
							let ret = DeserializeObjectInternal(val, innerObj);

							switch (ret)
							{
							case .Err(let err):
								return .Err(.ERROR_PARSING);
							case .Ok:
								var addMethodRes = fieldType.GetMethod("Add", .ExactBinding);

								switch (addMethodRes)
								{
								case .Ok(let method):
									method.Invoke(fieldValue, innerObj);
								case .Err(let err):
									return .Err(.CANNOT_ASSIGN_VALUE);
								}
							}
						}
					}
				}
				else
				{
					switch (fieldType)
					{
					case typeof(String):
						let res = jsonObj.Get<String>(fieldName);

						switch (res)
						{
						case .Err(let err):
							return .Err(.ERROR_PARSING);
						case .Ok(String val):
							field.SetValue(obj, new String(val));
						}
					default:
						let innerObj = fieldType.CreateObject().Get();
						let innerJsonObjRes = jsonObj.Get<JSONObject>(fieldName);

						switch (innerJsonObjRes)
						{
						case .Err(.INVALID_TYPE):
							let res = jsonObj.Get<JSON_LITERAL>(fieldName);

							if (res == .Err(.INVALID_TYPE))
							{
								return .Err(.ERROR_PARSING);
							}
							else
							{
								valueSet = field.SetValue(obj, res.Value);
							}
						case .Ok(let val):
							let ret = DeserializeObjectInternal(val, innerObj);

							switch (ret)
							{
							case .Err(let err):
								return .Err(.ERROR_PARSING);
							case .Ok:
								valueSet = field.SetValue(obj, innerObj);
							}
						default:
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

			return typeName.Equals("JsonList");
		}

		private static bool IsList(Type type)
		{
			let typeName = scope String();
			type.GetName(typeName);

			return typeName.Equals("JsonList");
		}

		private static Result<DESERIALIZE_ERRORS> HasField(JSONObject jsonObj, Object obj, FieldInfo field)
		{
			let fieldName = scope String(field.Name);
			let fieldVariant = field.GetValue(obj).Value;
			let fieldVariantType = fieldVariant.VariantType;

			if (fieldVariantType.IsPrimitive)
			{
				switch (fieldVariantType)
				{
				case typeof(bool):
					if (!jsonObj.Contains(fieldName, fieldVariantType))
					{
						return .Ok(.FIELD_NOT_FOUND);
					}
				case typeof(int):
					if (!jsonObj.Contains(fieldName, typeof(int)))
					{
						return .Ok(.FIELD_NOT_FOUND);
					}
				case typeof(float):
					if (!jsonObj.Contains(fieldName, typeof(float)))
					{
						return .Ok(.FIELD_NOT_FOUND);
					}
				default:
					return .Ok(.INVALID_FIELD_TYPE);
				}
			}
			else if (fieldVariantType.IsObject)
			{
				switch (fieldVariantType)
				{
				case typeof(String):
					if (!jsonObj.Contains(fieldName, fieldVariantType))
					{
						return .Ok(.FIELD_NOT_FOUND);
					}
				default:
					let fieldValue = fieldVariant.Get<Object>();

					if (IsList(fieldValue))
					{
						if (!IsNullOrJSONArray(jsonObj, fieldName))
						{
							return .Ok(.INVALID_FIELD_TYPE);
						}
					}
					else if (!IsNullOrJSONObject(jsonObj, fieldName))
					{
						return .Ok(.INVALID_FIELD_TYPE);
					}
				}
			}

			return .Ok(.NO_ERROR);
		}

		private static bool IsNullOrJSONObject(JSONObject jsonObj, String key)
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
		}
	}
}
