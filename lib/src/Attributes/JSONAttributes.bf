using System;

namespace JSON_Beef.Attributes
{
	[AttributeUsage(.Field | .Property, .ReflectAttribute, ReflectUser=.All)]
	public struct IgnoreSerializeAttribute: Attribute
	{
	}
}
