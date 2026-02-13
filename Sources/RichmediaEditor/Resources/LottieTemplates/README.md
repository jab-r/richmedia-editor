# Lottie Animation Templates

This directory contains built-in Lottie animation templates for the richmedia editor.

## Adding Lottie Templates

To add real Lottie animations to this package:

1. **Find Lottie animations** from:
   - [LottieFiles.com](https://lottiefiles.com) - Free animated icons and illustrations
   - After Effects → Export using Bodymovin plugin
   - Custom animations created with design tools

2. **Download JSON files** for these templates:
   - `confetti.json` - Celebration effect
   - `sparkles.json` - Sparkle effects
   - `loading.json` - Loading spinner
   - `heart_beat.json` - Animated heart
   - `star_burst.json` - Star explosion
   - `checkmark.json` - Success checkmark

3. **Place JSON files** in this directory:
   ```
   Sources/RichmediaEditor/Resources/LottieTemplates/
   ├── confetti.json
   ├── sparkles.json
   ├── loading.json
   ├── heart_beat.json
   ├── star_burst.json
   └── checkmark.json
   ```

4. **Verify** files are valid Lottie JSON (must have `v`, `fr`, `ip`, `op`, `w`, `h` fields)

## Current Status

⚠️ **Placeholder templates are currently used** - The `loadTemplate()` method returns minimal JSON structures until real animation files are added.

## Recommended Sources

**Free Lottie Files:**
- https://lottiefiles.com/free - Thousands of free animations
- https://lottiefiles.com/featured - Curated high-quality animations

**Search terms for templates:**
- "confetti celebration"
- "sparkles magic"
- "loading spinner"
- "heart beat pulse"
- "star burst explosion"
- "checkmark success"

## License Considerations

When downloading from LottieFiles.com:
- Check the license (some require attribution)
- Prefer "Free" or "MIT" licensed animations
- Read terms of use before commercial distribution

## After Adding Files

After adding real Lottie JSON files, the `LottieTemplates.loadTemplate()` method will automatically load them using `Bundle.module`.
