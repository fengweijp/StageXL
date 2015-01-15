part of stagexl.media;

abstract class Sound {

  Sound() {
    var initEngine = SoundMixer.engine;
  }

  static SoundLoadOptions defaultLoadOptions = new SoundLoadOptions(
      mp3:true, mp4:true, ogg:true, ac3: true, wav:true);

  static Future<Sound> load(String url, [SoundLoadOptions soundLoadOptions = null]) {

    switch(SoundMixer.engine) {
      case "WebAudioApi" : return WebAudioApiSound.load(url, soundLoadOptions);
      case "AudioElement": return AudioElementSound.load(url, soundLoadOptions);
      default            : return MockSound.load(url, soundLoadOptions);
    }
  }

  /// Loads a sound encoded in the data URI scheme.
  ///
  ///     Sound.loadDataUri("data:audio/mpeg;base64,<data>")
  ///         .then((Sound sound) {
  ///       sound.play();
  ///     });
  static Future<Sound> loadDataUri(String dataUri) {
    switch(SoundMixer.engine) {
      case "WebAudioApi" : return WebAudioApiSound.loadDataUri(dataUri);
      case "AudioElement": return AudioElementSound.loadDataUri(dataUri);
      default            : return new Future<Sound>.value(new MockSound._());
    }
  }

  //-------------------------------------------------------------------------------------------------

  num get length;

  SoundChannel play([bool loop = false, SoundTransform soundTransform]);

  SoundChannel playSegment(num startTime, num duration, [
                           bool loop = false, SoundTransform soundTransform]);
}
