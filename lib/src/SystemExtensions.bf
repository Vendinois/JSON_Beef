namespace System
{
	extension Runtime
	{
		public static void AssertTrue(bool condition, String errorMsg)
		{
			if (!condition)
			{
				Internal.FatalError(errorMsg, 1);
			}
		}
	}
}
