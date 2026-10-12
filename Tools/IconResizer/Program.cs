using System;
using System.IO;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

class Program
{
    static int[] sizes = new[] { 36, 48, 72, 96, 144, 192, 512 };

    static int Main(string[] args)
    {
        try
        {
            string? src = null;
            string outDir;

            // Accept arguments or prompt the user; do not force a specific input style.
            if (args.Length >= 1 && !string.IsNullOrWhiteSpace(args[0]))
                src = args[0];
            else
            {
                Console.Write("Source image path: ");
                src = Console.ReadLine();
            }

            if (string.IsNullOrWhiteSpace(src))
            {
                Console.WriteLine("No source image provided.");
                return 1;
            }

            if (args.Length >= 2 && !string.IsNullOrWhiteSpace(args[1]))
                outDir = args[1];
            else
            {
                Console.Write("Output folder (leave empty to use Resources\\AppIcon): ");
                outDir = Console.ReadLine() ?? string.Empty;
            }

            if (string.IsNullOrWhiteSpace(outDir))
            {
                // Default to the project's Resources/AppIcon folder when available
                outDir = Path.Combine(Directory.GetCurrentDirectory(), "Resources", "AppIcon");
            }

            if (!File.Exists(src))
            {
                Console.WriteLine($"Source file not found: {src}");
                return 2;
            }

            Directory.CreateDirectory(outDir);

            using var bmp = new Bitmap(src);

            // Produce standard icon densities
            foreach (var s in sizes)
            {
                var dest = Path.Combine(outDir, $"icon_{s}.png");
                using var target = new Bitmap(s, s);
                using (var g = Graphics.FromImage(target))
                {
                    g.CompositingQuality = CompositingQuality.HighQuality;
                    g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                    g.SmoothingMode = SmoothingMode.HighQuality;
                    g.Clear(Color.Transparent);

                    // Aspect-fit the source into the square
                    var ratio = Math.Min((float)s / bmp.Width, (float)s / bmp.Height);
                    var width = (int)(bmp.Width * ratio);
                    var height = (int)(bmp.Height * ratio);
                    var x = (s - width) / 2;
                    var y = (s - height) / 2;
                    g.DrawImage(bmp, x, y, width, height);
                }
                target.Save(dest, ImageFormat.Png);
                Console.WriteLine($"Wrote {dest}");
            }

            // Generate adaptive icon layers (foreground with transparency + solid background)
            // Create 1024x1024 foreground (transparent background) and background (filled)
            var fgPath = Path.Combine(outDir, "foreground.png");
            var bgPath = Path.Combine(outDir, "background.png");
            int adaptiveSize = 1024;

            using (var fg = new Bitmap(adaptiveSize, adaptiveSize))
            using (var g = Graphics.FromImage(fg))
            {
                g.CompositingQuality = CompositingQuality.HighQuality;
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.SmoothingMode = SmoothingMode.HighQuality;
                g.Clear(Color.Transparent);

                // Draw the source scaled to 72% of the adaptive area to leave safe zone around edges
                var padRatio = 0.72f;
                var targetSize = (int)(adaptiveSize * padRatio);
                var ratio = Math.Min((float)targetSize / bmp.Width, (float)targetSize / bmp.Height);
                var width = (int)(bmp.Width * ratio);
                var height = (int)(bmp.Height * ratio);
                var x = (adaptiveSize - width) / 2;
                var y = (adaptiveSize - height) / 2;
                g.DrawImage(bmp, x, y, width, height);
                fg.Save(fgPath, ImageFormat.Png);
                Console.WriteLine($"Wrote foreground: {fgPath}");
            }

            using (var bg = new Bitmap(adaptiveSize, adaptiveSize))
            using (var g = Graphics.FromImage(bg))
            {
                g.CompositingQuality = CompositingQuality.HighQuality;
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.SmoothingMode = SmoothingMode.HighQuality;
                // Fill background with a neutral primary color; user can replace this if desired
                g.Clear(ColorTranslator.FromHtml("#0066F0"));
                bg.Save(bgPath, ImageFormat.Png);
                Console.WriteLine($"Wrote background: {bgPath}");
            }

            // Also create a high-resolution Play store icon (512x512)
            var playOut = Path.Combine(outDir, "icon_512_play.png");
            using (var play = new Bitmap(512, 512))
            using (var g = Graphics.FromImage(play))
            {
                g.CompositingQuality = CompositingQuality.HighQuality;
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.SmoothingMode = SmoothingMode.HighQuality;
                g.Clear(Color.Transparent);
                var ratio = Math.Min(512f / bmp.Width, 512f / bmp.Height);
                var width = (int)(bmp.Width * ratio);
                var height = (int)(bmp.Height * ratio);
                var x = (512 - width) / 2;
                var y = (512 - height) / 2;
                g.DrawImage(bmp, x, y, width, height);
                play.Save(playOut, ImageFormat.Png);
                Console.WriteLine($"Wrote Play icon: {playOut}");
            }

            return 0;
        }
        catch (Exception ex)
        {
            Console.WriteLine("Error: " + ex.Message);
            return 10;
        }
    }
}
