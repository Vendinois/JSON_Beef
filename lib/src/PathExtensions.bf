namespace System.IO
{
	extension Path
	{
		public static void Join(StringView pathA, StringView pathB, String outPath)
		{
			outPath.Clear();
			outPath.AppendF("{}{}{}", pathA, Path.DirectorySeparatorChar, pathB);
		}
	}
}
