using System;

namespace JSON_Beef
{
	[AttributeUsage(.Field | .Property, .ReflectAttribute, ReflectUser=.All)]
	public struct IgnoreSerializeAttribute: Attribute
	{
	}

	[AttributeUsage(.Class, ReflectUser=.All),
		AlwaysInclude(AssumeInstantiated=true),
		Reflect]
	public struct SerializableAttribute: Attribute
	{
	}
}
