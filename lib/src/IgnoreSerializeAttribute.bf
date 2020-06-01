using System;

namespace JSON_Beef
{
	[AttributeUsage(.Field | .Property | .Class | .Struct, .ReflectAttribute, ReflectUser=.All)]
	public struct IgnoreSerializeAttribute: Attribute
	{
	}

	[AttributeUsage(.Class | .Struct, .ReflectAttribute | .AlwaysIncludeTarget, ReflectUser=.All)]
	public struct SerializableAttribute: Attribute
	{

	}
}
