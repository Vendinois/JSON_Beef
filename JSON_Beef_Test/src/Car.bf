using System;
using System.Collections;

namespace JSON_Beef_Test
{
	[AlwaysInclude(AssumeInstantiated=true, IncludeAllMethods=true)]
	[Reflect]
	public struct Car
	{
		public int Age;
		public float Speed;
		public String Name = new .();

		public List<String> Sellers;
	}
}
