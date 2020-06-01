using System;
using System.Collections;
using System.Reflection;

namespace JSON_Beef
{
	public class JSONSerializer
	{
		public static Result<JSONObject> Serialize(Object object)
		{
			let type = object.GetType();
			var fields = type.GetFields();

			let json = new JSONObject();

			for (var field in fields)
			{
				let shouldIgnore = field.GetCustomAttribute<IgnoreSerializeAttribute>();
				let isPrivate = field.HasFieldFlag(.PrivateScope);

				if ((shouldIgnore == .Ok) || isPrivate)
				{
					continue;
				}

				let name = scope String(field.Name);
				var value = field.GetValue(object).Get();
				let valueType = value.VariantType;

				if (valueType == null)
				{
					json.Add(name, JSON_LITERAL.NULL);
				}
				else
				{
					switch (valueType)
					{
					case typeof(String):
						json.Add(name, value.Get<String>());
					case typeof(int):
						json.Add(name, value.Get<int>());
					case typeof(float):
						json.Add(name, value.Get<float>());
					case typeof(bool):
						json.Add(name, JSONUtil.BoolToLiteral(value.Get<bool>()));
					case typeof(Array):
						ThrowUnimplemented();
					default:
						let res = JSONSerializer.Serialize(value.Get<Object>());

						if (res == .Err)
						{
							delete json;
							return .Err;
						}

						json.Add(name, res.Get());
						delete res.Get();
					}
				}
			}

			return .Ok(json);
		}
	}
}
