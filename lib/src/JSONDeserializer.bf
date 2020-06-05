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
			TYPE_NOT_MATCH,
			ERROR_PARSING
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
				res = DeserializeArrayInternal<T>(json, ref finalObj);
			case .OBJECT:
				res = DeserializeObjectInternal<T>(json, ref finalObj);
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

		private static Result<void, DESERIALIZE_ERRORS> DeserializeObjectInternal<T>(String json, ref T obj)
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
				return .Err(.TYPE_NOT_MATCH);
			}


			return .Ok;
		}

		private static Result<void, DESERIALIZE_ERRORS> DeserializeArrayInternal<T>(String json, ref T obj)
		{
			return .Ok;
		}

		private static bool AreTypeMatching<T>(JSONObject jsonObj, T obj)
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

				if (!HasField<T>(jsonObj, obj, field))
				{
					return false;
				}
			}
			return true;
		}

		private static bool AreBaseTypeMatching<T>(JSONObject jsonObj, T obj)
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
				if (!HasField<T>(jsonObj, obj, field) || !AreBaseTypeMatching(jsonObj, fieldValue))
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

		private static bool HasField<T>(JSONObject jsonObj, T obj, FieldInfo field)
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
