# Audio Files Directory

Place your MP3 files in this directory.

## Getting HTTP URLs for Your MP3 Files

Once you upload MP3 files here, they will be accessible via:

### GitHub Raw URLs (Works immediately)
```
https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/YOUR_FILE.mp3
```

**Example:** If you upload `song.mp3`, the URL will be:
```
https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/song.mp3
```

### GitHub Pages URLs (After enabling GitHub Pages)
```
https://tedacoder.github.io/test-mp3/audio/YOUR_FILE.mp3
```

## Usage with xsound

### Method 1: HTML5 Audio Element
```html
<audio controls>
  <source src="https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/YOUR_FILE.mp3" type="audio/mpeg">
</audio>
```

### Method 2: JavaScript Audio Object
```javascript
const audio = new Audio('https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/YOUR_FILE.mp3');
audio.play();
```

### Method 3: Web Audio API (for xsound integration)
```javascript
const audioContext = new AudioContext();

fetch('https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/YOUR_FILE.mp3')
  .then(response => response.arrayBuffer())
  .then(buffer => audioContext.decodeAudioData(buffer))
  .then(audioBuffer => {
    const source = audioContext.createBufferSource();
    source.buffer = audioBuffer;
    source.connect(audioContext.destination);
    source.start(0);
  });
```

### Method 4: Using XSound Library
If you're using the XSound library specifically:
```javascript
X('https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/YOUR_FILE.mp3').setup({
  decode: function() {
    // Audio loaded and decoded
    X('audio').start();
  }
});
```

## File Size Limits

- Individual files: up to 100MB (GitHub limit)
- For larger files, consider using GitHub Releases
- Recommended: Keep files under 10MB for better web performance

## CORS Support

GitHub's raw.githubusercontent.com domain supports CORS, so these URLs will work in web browsers without cross-origin issues.

## Testing Your URLs

You can test your MP3 URLs by:
1. Opening them directly in a browser
2. Using the example player at `examples/index.html`
3. Testing with curl: `curl -I <your-url>` to verify the file is accessible
