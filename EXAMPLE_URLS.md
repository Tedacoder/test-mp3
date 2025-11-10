# Example MP3 URLs

Once you add MP3 files to the `audio/` directory, they will be accessible via HTTP URLs.

## Example URLs

If you add these files:
- `audio/song1.mp3`
- `audio/song2.mp3`
- `audio/background.mp3`

They will be accessible at:

### Using GitHub Raw URLs (Recommended)
```
https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/song1.mp3
https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/song2.mp3
https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/background.mp3
```

### Using GitHub Pages (After enabling)
```
https://tedacoder.github.io/test-mp3/audio/song1.mp3
https://tedacoder.github.io/test-mp3/audio/song2.mp3
https://tedacoder.github.io/test-mp3/audio/background.mp3
```

## Quick Test

You can verify a URL works by:
1. Pasting it into your browser's address bar
2. The browser should download or play the MP3 file

## Usage in xsound

```javascript
// Example with XSound library
X('audio').setup({
  src: 'https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/song1.mp3',
  decode: function(event) {
    console.log('Song loaded!');
    X('audio').start();
  }
});

// Example with simple Audio object
const audio = new Audio('https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/song1.mp3');
audio.play();
```

## Next Steps

1. Add your MP3 files to the `audio/` directory
2. Commit and push to GitHub
3. Use the URLs in your radio application
4. Test with the example player at `examples/index.html`
