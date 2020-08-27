using System;

namespace JSON_Beef.Attributes
{
	[AttributeUsage(.Field | .Property | .StaticField, .ReflectAttribute, ReflectUser=.All)]
	public struct IgnoreSerializeAttribute: Attribute
	{
	}
}
