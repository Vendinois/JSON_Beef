using System;

namespace JSON_Beef
{
	[AttributeUsage(.Field | .Property, .ReflectAttribute, ReflectUser=.All)]
	public struct IgnoreSerializeAttribute: Attribute
	{
	}
}
