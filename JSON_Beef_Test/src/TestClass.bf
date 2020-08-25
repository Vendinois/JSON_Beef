using System;
using System.Collections;

namespace JSON_Beef_Test
{
	[AlwaysInclude(AssumeInstantiated=true, IncludeAllMethods=true)]
	[Reflect]
	public class TestClass
	{
		public List<List<String>> MultipleList = null ~ {
			if (_ != null)
			{
				for (var value in _)
					DeleteContainerAndItems!(value);
				delete _;
			}
		};
	}
}
