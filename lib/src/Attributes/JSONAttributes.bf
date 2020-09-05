using System;

namespace JSON_Beef.Attributes
{
	[AttributeUsage(.Field | .Property | .StaticField, .ReflectAttribute, ReflectUser=.All)]
	public struct IgnoreSerializeAttribute: Attribute
	{
	}

	[AttributeUsage(.All, .ReflectAttribute | .AlwaysIncludeTarget)]
	public struct SerializableAttribute: Attribute
	{
		public void TestAMethod()
		{
			Console.WriteLine("Test A method");
		}
	}
}
