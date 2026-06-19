# xsound Integration Guide

Quick reference for using GitHub-hosted MP3 files with xsound and other audio libraries.

## Quick Start

Your MP3 files hosted on GitHub are accessible via:
```
https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/{filename}.mp3
```

## Common Audio Library Examples

### 1. HTML5 Audio (Simplest)
```html
<audio id="myAudio" controls>
  <source src="https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/song.mp3" type="audio/mpeg">
</audio>

<script>
  const audio = document.getElementById('myAudio');
  audio.play();
</script>
```

### 2. JavaScript Audio Object
```javascript
const audio = new Audio('https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/song.mp3');

// Play
audio.play();

// Pause
audio.pause();

// Volume control (0.0 to 1.0)
audio.volume = 0.5;

// Loop
audio.loop = true;
```

### 3. Web Audio API (Advanced)
```javascript
const audioContext = new (window.AudioContext || window.webkitAudioContext)();
const audioUrl = 'https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/song.mp3';

fetch(audioUrl)
  .then(response => response.arrayBuffer())
  .then(arrayBuffer => audioContext.decodeAudioData(arrayBuffer))
  .then(audioBuffer => {
    const source = audioContext.createBufferSource();
    source.buffer = audioBuffer;
    
    // Add effects (optional)
    const gainNode = audioContext.createGain();
    source.connect(gainNode);
    gainNode.connect(audioContext.destination);
    gainNode.gain.value = 0.5; // Volume control
    
    source.start(0);
  })
  .catch(error => console.error('Error loading audio:', error));
```

### 4. XSound Library
If using the XSound library (https://github.com/Korilakkuma/XSound):

```html
<script src="https://cdn.jsdelivr.net/npm/xsound@latest/build/xsound.min.js"></script>
<script>
  // Single audio source
  X('audio').setup({
    src: 'https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/song.mp3',
    decode: function(event) {
      console.log('Audio loaded');
      X('audio').start();
    }
  });
  
  // With effects
  X('audio').module('delay').param({
    time: 0.5,
    dry: 0.5,
    wet: 0.3
  });
  
  // Play
  X('audio').start();
  
  // Stop
  X('audio').stop();
</script>
```

### 5. Howler.js
```javascript
// Include Howler.js first
const sound = new Howl({
  src: ['https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/song.mp3'],
  html5: true,
  onload: function() {
    console.log('Audio loaded');
  }
});

sound.play();
```

### 6. Tone.js
```javascript
const player = new Tone.Player({
  url: 'https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/song.mp3',
  onload: () => {
    console.log('Audio loaded');
  }
}).toDestination();

Tone.loaded().then(() => {
  player.start();
});
```

## Radio/Playlist Example

```javascript
class SimpleRadio {
  constructor(playlist) {
    this.playlist = playlist;
    this.currentIndex = 0;
    this.audio = new Audio();
    
    this.audio.addEventListener('ended', () => this.next());
  }
  
  play() {
    this.audio.src = this.playlist[this.currentIndex];
    this.audio.play();
  }
  
  pause() {
    this.audio.pause();
  }
  
  next() {
    this.currentIndex = (this.currentIndex + 1) % this.playlist.length;
    this.play();
  }
  
  previous() {
    this.currentIndex = (this.currentIndex - 1 + this.playlist.length) % this.playlist.length;
    this.play();
  }
}

// Usage
const radio = new SimpleRadio([
  'https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/song1.mp3',
  'https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/song2.mp3',
  'https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/song3.mp3'
]);

radio.play();
```

## CORS and Security

✅ GitHub's `raw.githubusercontent.com` has CORS enabled  
✅ Files are served with proper MIME types  
✅ HTTPS is enforced for security  

## Best Practices

1. **Use HTTPS URLs** - Always use `https://` for security
2. **Cache wisely** - GitHub raw URLs are cached, changes may take time to reflect
3. **File size** - Keep MP3 files optimized (128-192 kbps is usually sufficient for web)
4. **Fallbacks** - Provide fallback URLs or error handling
5. **Loading states** - Show loading indicators while audio loads

## Troubleshooting

### Audio not loading?
- Verify the URL is accessible (open in browser)
- Check browser console for CORS errors
- Ensure file path is correct (case-sensitive)

### Audio not playing?
- User interaction required: most browsers require user gesture (click) before playing audio
- Check browser autoplay policies
- Verify audio format is supported (MP3 is widely supported)

## Example Repository Structure

```
test-mp3/
├── audio/
│   ├── song1.mp3
│   ├── song2.mp3
│   └── ambient.mp3
├── examples/
│   └── index.html (demo player)
└── README.md
```

Each file at `audio/song1.mp3` becomes:
```
https://raw.githubusercontent.com/Tedacoder/test-mp3/main/audio/song1.mp3
```
