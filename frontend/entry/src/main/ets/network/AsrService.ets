import http from '@ohos.net.http';
import util from '@ohos.util';
import hilog from '@ohos.hilog';

// 🌟 解决 arkts-no-untyped-obj-literals：严格定义请求体类
class BaiduAsrRequest {
  format: string = "pcm";
  rate: number = 16000;
  channel: number = 1;
  cuid: string = "hmos_smart_gateway";
  token: string = "";
  lan: string = "zh";
  speech: string = "";
  len: number = 0;
}

export class AsrService {
  private static readonly API_KEY = 'cqdpsNBC4MiLFJSWcJBzncgx';//在此处填入百度的API_KEY
  private static readonly SECRET_KEY = 'eHakOw1IXlGfqyLleXffA9YIuVfNNay8';//在此处填入百度的SECRET_KEY

  private static accessToken: string = '';
  private static tokenExpireTime: number = 0;

  private static async getAccessToken(): Promise<string> {
    // 🌟 解决 arkts-no-standalone-this：全部替换为 AsrService
    if (AsrService.accessToken && Date.now() < AsrService.tokenExpireTime) {
      return AsrService.accessToken;
    }

    let httpRequest = http.createHttp();
    let url = `https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id=${AsrService.API_KEY}&client_secret=${AsrService.SECRET_KEY}`;

    try {
      let response = await httpRequest.request(url, { method: http.RequestMethod.POST });
      if (response.responseCode === 200) {
        // 🌟 解决 arkts-no-any-unknown：使用 Object 替代 any
        let resJson = JSON.parse(response.result as string) as Record<string, Object>;
        AsrService.accessToken = resJson['access_token'] as string;
        AsrService.tokenExpireTime = Date.now() + ((resJson['expires_in'] as number) - 600) * 1000;
        return AsrService.accessToken;
      }
    } catch (err) {
      hilog.error(0x0000, 'ASR_SERVICE', `获取Token失败: ${JSON.stringify(err)}`);
    } finally {
      httpRequest.destroy();
    }
    return '';
  }

  public static async recognize(pcmBuffer: ArrayBuffer): Promise<string> {
    if (!pcmBuffer || pcmBuffer.byteLength === 0) return '';

    let token = await AsrService.getAccessToken();
    if (!token) {
      hilog.error(0x0000, 'ASR_SERVICE', '无法获取AccessToken，识别中止');
      return '';
    }

    try {
      let base64Helper = new util.Base64Helper();
      let uint8Array = new Uint8Array(pcmBuffer);
      let base64String = base64Helper.encodeToStringSync(uint8Array);

      // 🌟 使用实体类实例化，避开匿名对象报错
      let requestData = new BaiduAsrRequest();
      requestData.token = token;
      requestData.speech = base64String;
      requestData.len = pcmBuffer.byteLength;

      let httpRequest = http.createHttp();
      let response = await httpRequest.request('https://vop.baidu.com/server_api', {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: JSON.stringify(requestData)
      }
      );

      if (response.responseCode === 200) {
        let resJson = JSON.parse(response.result as string) as Record<string, Object>;
        let errNo = resJson['err_no'] as number;
        if (errNo === 0 && resJson['result']) {
          let resultArray = resJson['result'] as string[];
          return resultArray[0];
        }
      }
    } catch (err) {
      hilog.error(0x0000, 'ASR_SERVICE', `识别网络异常: ${JSON.stringify(err)}`);
    }
    return '';
  }
}