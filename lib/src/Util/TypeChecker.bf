using System;
using System.Reflection;

namespace JSON_Beef.Util
{
	public static class TypeChecker
	{
		public static bool IsTypeList(Type type)
		{
			let typeName = scope String();
			type.GetName(typeName);

			return typeName.Equals("List");
		}

		public static bool IsTypeList(Object object)
		{
			return IsTypeList(object.GetType());
		}

		public static bool IsUserObject(Type type)
		{
			if (type.IsObject && (typeof(String) != type))
			{
				return true;
			}

			return false;
		}

		public static bool IsPrimitive(Type type)
		{
			return type.IsPrimitive || (typeof(String) == type);
		}
	}
}
