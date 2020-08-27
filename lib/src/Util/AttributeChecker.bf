using System.Reflection;
using JSON_Beef.Attributes;

namespace JSON_Beef.Util
{
	public static class AttributeChecker
	{
		public static bool ShouldIgnore(FieldInfo field)
		{
			let shouldIgnore = field.GetCustomAttribute<IgnoreSerializeAttribute>();

			return ((shouldIgnore == .Ok) || FieldHelper.HasFlag(field, .PrivateScope) || FieldHelper.HasFlag(field, .Private));
		}
	}
}
