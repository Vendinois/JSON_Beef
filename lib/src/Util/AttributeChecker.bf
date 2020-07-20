using System.Reflection;

namespace JSON_Beef.Util
{
	public static class AttributeChecker
	{
		public static bool ShouldIgnore(FieldInfo field)
		{
			let shouldIgnore = field.GetCustomAttribute<IgnoreSerializeAttribute>();

			return ((shouldIgnore == .Ok) || field.HasFieldFlag(.PrivateScope) || field.HasFieldFlag(.Private));
		}
	}
}
