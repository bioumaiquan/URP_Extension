using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEditor;

public class TextureFormatConverter : Editor
{
	[MenuItem("Tools/转TGA")]
    static void ConvertToTGA()
    {
		string[] GUIDs = Selection.assetGUIDs;
		if(GUIDs == null)
		{
			return;
		}

		for (var i = 0; i < GUIDs.Length; i++)
		{
			string path = AssetDatabase.GUIDToAssetPath(GUIDs[i]);
			Texture2D raw = AssetDatabase.LoadAssetAtPath(path, typeof(Texture2D)) as Texture2D;
			TextureImporter importer = TextureImporter.GetAtPath(path) as TextureImporter;
			importer.isReadable = true;
			importer.SaveAndReimport();

			Texture2D newTex = new Texture2D(raw.width, raw.height, TextureFormat.RGBA32, true, false);
			newTex.SetPixels(raw.GetPixels());
			var bytes = newTex.EncodeToTGA();

			string newPath = path.Remove(path.Length - 3);
			newPath += "tga";
            File.WriteAllBytes(newPath, bytes);

			importer.isReadable = false;
			importer.SaveAndReimport();

			AssetDatabase.ImportAsset(newPath);
		}
    }
}
