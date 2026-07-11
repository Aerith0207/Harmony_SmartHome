import audio from '@ohos.multimedia.audio';
import hilog from '@ohos.hilog';

export class AudioCaptureUtil {
  private static audioCapturer: audio.AudioCapturer | null = null;
  private static isRecording: boolean = false;
  private static audioBufferList: ArrayBuffer[] = [];

  public static async startRecording(): Promise<void> {
    if (AudioCaptureUtil.isRecording) return;
    AudioCaptureUtil.audioBufferList = [];

    let audioStreamInfo: audio.AudioStreamInfo = {
      samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
      channels: audio.AudioChannel.CHANNEL_1,
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
      encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
    };

    let audioCapturerInfo: audio.AudioCapturerInfo = {
      source: audio.SourceType.SOURCE_TYPE_MIC,
      capturerFlags: 0
    };

    try {
      AudioCaptureUtil.audioCapturer = await audio.createAudioCapturer({ streamInfo: audioStreamInfo, capturerInfo: audioCapturerInfo });
      AudioCaptureUtil.isRecording = true;
      await AudioCaptureUtil.audioCapturer.start();

      while (AudioCaptureUtil.isRecording && AudioCaptureUtil.audioCapturer) {
        let bufferSize = await AudioCaptureUtil.audioCapturer.getBufferSize();
        let buffer = await AudioCaptureUtil.audioCapturer.read(bufferSize, true);
        if (buffer && buffer.byteLength > 0) {
          AudioCaptureUtil.audioBufferList.push(buffer);
        }
      }
    } catch (err) {
      hilog.error(0x0000, 'AUDIO_CAP', `录音启动失败: ${JSON.stringify(err)}`);
    }
  }

  public static async stopRecording(): Promise<ArrayBuffer> {
    AudioCaptureUtil.isRecording = false;

    if (AudioCaptureUtil.audioCapturer) {
      try {
        await AudioCaptureUtil.audioCapturer.stop();
        await AudioCaptureUtil.audioCapturer.release();
        AudioCaptureUtil.audioCapturer = null;
      } catch(e) {}
    }

    let totalLength = 0;
    for (let i = 0; i < AudioCaptureUtil.audioBufferList.length; i++) {
      totalLength += AudioCaptureUtil.audioBufferList[i].byteLength;
    }

    let resultBuffer = new Uint8Array(totalLength);
    let offset = 0;
    for (let i = 0; i < AudioCaptureUtil.audioBufferList.length; i++) {
      let buf = AudioCaptureUtil.audioBufferList[i];
      resultBuffer.set(new Uint8Array(buf), offset);
      offset += buf.byteLength;
    }

    return resultBuffer.buffer;
  }
}