# test-mp3
mp3 for the radio I designed

## Getting HTTP URLs for MP3 Files (for xsound)

This repository provides MP3 files that can be accessed via HTTP URLs for use with xsound and other web audio applications.

### Method 1: Using GitHub Raw URLs (Recommended)

After uploading your MP3 files to the `audio/` directory, you can access them via GitHub's raw content URLs:

```
https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/YOUR_FILE.mp3
```

**Example:**
If you have a file at `audio/song.mp3`, the URL would be:
```
https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/song.mp3
```

### Method 2: Using GitHub Pages

1. Enable GitHub Pages in your repository settings (Settings > Pages)
2. Select the `main` branch as the source
3. Your MP3 files will be available at:
```
https://tedacoder.github.io/test-mp3/audio/YOUR_FILE.mp3
```

### Using with xsound

Once you have the HTTP URL, you can use it with xsound:

```javascript
// Create xsound instance
const audio = new Audio('https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/YOUR_FILE.mp3');

// Or with Web Audio API
const context = new AudioContext();
fetch('https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/YOUR_FILE.mp3')
  .then(response => response.arrayBuffer())
  .then(buffer => context.decodeAudioData(buffer))
  .then(audioBuffer => {
    // Use the audio buffer with xsound
  });
```

### Directory Structure

```
test-mp3/
├── audio/              # Place your MP3 files here
├── examples/           # Example HTML pages using xsound
└── README.md          # This file
```

### Adding Your MP3 Files

1. Place your MP3 files in the `audio/` directory
2. Commit and push to GitHub
3. Use the URLs as described above

### Notes

- GitHub has file size limits (typically 100MB for individual files)
- For better performance with large files, consider using GitHub Releases
- CORS is enabled for raw.githubusercontent.com, so files will work in web applications
