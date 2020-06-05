using System;
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
			CANNOT_ASSIGN_VALUE
		}

		public static Result<T, DESERIALIZE_ERRORS> Deserialize<T>(String json) where T: new
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
				return .Err(.ERROR_PARSING);
			}

			switch (res)
			{
			case .Err(let err):
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
			if (!AreTypeMatching(jsonObj, obj))
			{
				return .Err(.TYPE_NOT_MATCHING);
			}

			let finalRes = DeserializeObjectInternal(jsonObj, obj);

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
			let fieldVariant = field.GetValue(obj).Value;
			let fieldType = fieldVariant.VariantType;
			let fieldValue = fieldVariant.Get<Object>();

			var valueSet = Result<void, FieldInfo.Error>();

			if (IsList(fieldValue))
			{
				if (fieldValue == null)
				{
					return .Err(.CANNOT_ASSIGN_VALUE);
				}

				let jsonArrayRes = jsonObj.Get<JSONArray>(fieldName);

				if (jsonArrayRes == .Err(.INVALID_TYPE))
				{
					return .Err(.ERROR_PARSING);
				}

				// Todo: Traverse the JSONArray, create the right object if needed and add to the field
				// I think the call to the Add method of the List is as follow:
				// fieldType.GetMethod("Add").Get().Invoke(fieldValue, param);

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
						let val = variant.Get<String>();
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
						/*let val = variant.Get<JSONArray>();

						let res = DeserializeArrayInternal(val, innerObj);

						switch (res)
						{
						case .Err(let err):
							return res;
						case .Ok:
							break;
						}*/
						break;
					case typeof(JSONObject):
						let val = variant.Get<JSONObject>();

						let generic = fieldType as SpecializedGenericType;
						let genericType = generic.GetGenericArg(0) as TypeInstance;
						genericType.CreateObject();

						//var innerObj = genericType.CreateObject();
						/*let ret = DeserializeObjectInternal(val, innerObj.Get());

						switch (ret)
						{
						case .Err(let err):
							return .Err(.ERROR_PARSING);
						case .Ok:
							break;
						}*/
					}
				}
			}
			else
			{
				switch (fieldType)
				{
				case typeof(String), typeof(int), typeof(float):
					let res = jsonObj.Get(fieldName, fieldType);

					switch (res)
					{
					case .Err(let err):
						return .Err(.ERROR_PARSING);
					case .Ok(let val):
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
						valueSet = field.SetValue(obj, val);
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

		private static bool AreTypeMatching(JSONObject jsonObj, Object obj)
		{
			let type = obj.GetType();
			let fields = type.GetFields();

			if (!AreBaseTypeMatching(jsonObj, obj))
			{
				return false;
			}

			for (var field in fields)
			{
				if (ShouldIgnore(field))
				{
					continue;
				}

				if (!HasField(jsonObj, obj, field))
				{
					return false;
				}
			}
			return true;
		}

		private static bool AreBaseTypeMatching(JSONObject jsonObj, Object obj)
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
				if (ShouldIgnore(field))
				{
					continue;
				}

				let fieldValue = field.GetValue(obj).Get().Get<Object>();
				if (!HasField(jsonObj, obj, field) || !AreBaseTypeMatching(jsonObj, fieldValue))
				{
					return false;
				}
			}

			return true;
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

		private static bool HasField(JSONObject jsonObj, Object obj, FieldInfo field)
		{
			let fieldName = scope String(field.Name);
			let fieldVariant = field.GetValue(obj).Value;
			let fieldVariantType = fieldVariant.VariantType;
			let fieldValue = fieldVariant.Get<Object>();

			if (IsList(fieldValue))
			{
				if (!IsNullOrJSONArray(jsonObj, fieldName))
				{
					return false;
				}
			}
			else
			{
				switch (fieldVariantType)
				{
				case typeof(String), typeof(int), typeof(bool), typeof(float):
					if (!jsonObj.Contains(fieldName, fieldVariantType))
					{
						return false;
					}
				default:
					if (!IsNullOrJSONObject(jsonObj, fieldName))
					{
						return false;
					}
				}
			}
			return true;
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
