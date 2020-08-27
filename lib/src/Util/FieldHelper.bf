using System;
using System.Reflection;

namespace JSON_Beef.Util
{
	public static class FieldHelper
	{
		public static bool HasFlag(FieldInfo field, FieldFlags flagIn)
		{
			let flags = (int)field.[Friend]mFieldData.mFlags;
			let flag = (int)flagIn;

			return (flags & flag) != 0;
		}
	}
}
