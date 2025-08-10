# Verification Sound Assets

This directory contains sound files for random verification alerts in the Stika Rider app.

## Required Sound Files

Place the following MP3 audio files in this directory:

### 1. verification_alert.mp3
- **Purpose**: Initial verification alert sound
- **Duration**: 2-3 seconds
- **Style**: Professional attention-getting tone
- **Volume**: Medium intensity
- **Usage**: When random verification is first triggered

### 2. verification_urgent.mp3
- **Purpose**: Urgent verification alert for repeated notifications
- **Duration**: 1-2 seconds
- **Style**: More intense, urgent tone
- **Volume**: Higher intensity
- **Usage**: When verification notification is repeated or time is running out

### 3. verification_timeout_warning.mp3
- **Purpose**: Warning sound when verification timeout is approaching
- **Duration**: 1-2 seconds
- **Style**: Warning beep or chime
- **Volume**: Medium-high intensity
- **Usage**: 2-3 minutes before verification expires

### 4. verification_success.mp3
- **Purpose**: Success confirmation sound
- **Duration**: 1-2 seconds
- **Style**: Pleasant success chime
- **Volume**: Medium intensity
- **Usage**: When verification photo is successfully submitted

### 5. verification_failed.mp3
- **Purpose**: Failure notification sound
- **Duration**: 1-2 seconds
- **Style**: Error tone (not too harsh)
- **Volume**: Medium intensity
- **Usage**: When verification fails or is rejected

## Sound Requirements

- **Format**: MP3 (preferred) or WAV
- **Sample Rate**: 44.1kHz or 48kHz
- **Bit Rate**: 128kbps or higher
- **Size**: Keep under 100KB per file for app performance
- **Quality**: Clear, professional audio quality

## Implementation Notes

These sounds are played using the `VerificationSoundService` class which uses the `audioplayers` package. The service includes:

- Volume control
- Sound enable/disable toggle
- Vibration patterns
- Error handling
- Debug logging

## Testing

Use the `VerificationSoundService.testAllSounds()` method to test all sound files during development.

## Fallback

If sound files are missing, the service will fail gracefully and only show visual notifications without breaking the verification flow.