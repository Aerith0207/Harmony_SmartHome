import huks from '@ohos.security.huks';
import util from '@ohos.util';
import hilog from '@ohos.hilog';

export class CryptoUtil {
  static readonly keyAlias: string = 'SmartHome_AES_Key_V11';

  // 仅用于初次烧录时的密钥下发，后续业务层加解密绝不读取此变量
  private static readonly KEY_BYTES = new Uint8Array([
    0x2B, 0x7E, 0x15, 0x16, 0x28, 0xAE, 0xD2, 0xA6,
    0xAB, 0xF7, 0x15, 0x88, 0x09, 0xCF, 0x4F, 0x3C
  ]);

  private static readonly IV_BYTES = new Uint8Array([
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
    0x08, 0x09, 0x0A, 0x0B
  ]);

  public static async initKeyStore(): Promise<void> {
    let properties: Array<huks.HuksParam> = [
      { tag: huks.HuksTag.HUKS_TAG_ALGORITHM, value: huks.HuksKeyAlg.HUKS_ALG_AES },
      { tag: huks.HuksTag.HUKS_TAG_PURPOSE, value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT | huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT },
      { tag: huks.HuksTag.HUKS_TAG_KEY_SIZE, value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_128 },
      { tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE, value: huks.HuksCipherMode.HUKS_MODE_GCM },
      { tag: huks.HuksTag.HUKS_TAG_PADDING, value: huks.HuksKeyPadding.HUKS_PADDING_NONE }
    ];

    try {
      // 🌟 修复 1：严谨判断布尔返回值，确保密钥真实落盘
      let isExist = false;
      try {
        isExist = await huks.hasKeyItem(CryptoUtil.keyAlias, { properties: properties });
      } catch (e) {
        isExist = false;
      }

      if (!isExist) {
        let options: huks.HuksOptions = { properties: properties, inData: CryptoUtil.KEY_BYTES };
        await huks.importKeyItem(CryptoUtil.keyAlias, options);
        hilog.info(0x0000, 'HUKS_STORE', '✅ AES核心密钥已成功导入并隔离至底层TEE环境');
      } else {
        hilog.info(0x0000, 'HUKS_STORE', '✅ TEE安全区已存在托管密钥，跳过导入');
      }
    } catch (error) {
      hilog.error(0x0000, 'HUKS_STORE', `❌ 密钥托管失败: ${JSON.stringify(error)}`);
    }
  }

  public static async encrypt(plainText: string): Promise<Uint8Array> {
    let properties: Array<huks.HuksParam> = [
      { tag: huks.HuksTag.HUKS_TAG_ALGORITHM, value: huks.HuksKeyAlg.HUKS_ALG_AES },
      { tag: huks.HuksTag.HUKS_TAG_PURPOSE, value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT },
      { tag: huks.HuksTag.HUKS_TAG_KEY_SIZE, value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_128 },
      { tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE, value: huks.HuksCipherMode.HUKS_MODE_GCM },
      { tag: huks.HuksTag.HUKS_TAG_PADDING, value: huks.HuksKeyPadding.HUKS_PADDING_NONE },
      { tag: huks.HuksTag.HUKS_TAG_NONCE, value: CryptoUtil.IV_BYTES }
      // 🌟 修复 2：彻底删除了长度为 0 的 ASSOCIATED_DATA，规避 C++ 内存分配崩溃
    ];

    let options: huks.HuksOptions = {
      properties: properties,
      inData: new util.TextEncoder().encodeInto(plainText)
    };

    try {
      let session = await huks.initSession(CryptoUtil.keyAlias, options);
      let result = await huks.finishSession(session.handle, options);

      if (!result.outData) {
        throw new Error("HUKS 加密未返回有效载荷");
      }
      return result.outData;

    } catch (error) {
      let e = error as Error;
      hilog.error(0x0000, 'CryptoUtil', 'HUKS底层加密被阻断');
      throw new Error(e.message ? e.message : "HUKS加密未知异常");
    }
  }

  public static async decrypt(cipherWithTag: Uint8Array): Promise<string> {
    // 🌟 核心修复 1：手动剥离最后 16 字节的 GCM 认证标签 (AE_TAG)
    if (cipherWithTag.length <= 16) {
      hilog.error(0x0000, 'CryptoUtil', '密文长度不足，无法提取 Tag');
      return "";
    }
    let pureCipherData = cipherWithTag.slice(0, cipherWithTag.length - 16);
    let aeTag = cipherWithTag.slice(cipherWithTag.length - 16);

    let properties: Array<huks.HuksParam> = [
      { tag: huks.HuksTag.HUKS_TAG_ALGORITHM, value: huks.HuksKeyAlg.HUKS_ALG_AES },
      { tag: huks.HuksTag.HUKS_TAG_PURPOSE, value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT },
      { tag: huks.HuksTag.HUKS_TAG_KEY_SIZE, value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_128 },
      { tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE, value: huks.HuksCipherMode.HUKS_MODE_GCM },
      { tag: huks.HuksTag.HUKS_TAG_PADDING, value: huks.HuksKeyPadding.HUKS_PADDING_NONE },
      { tag: huks.HuksTag.HUKS_TAG_NONCE, value: CryptoUtil.IV_BYTES },
      // 🌟 核心修复 2：必须在 initSession 前，将切下来的 Tag 传给底层硬件
      { tag: huks.HuksTag.HUKS_TAG_AE_TAG, value: aeTag }
    ];

    let options: huks.HuksOptions = {
      properties: properties,
      inData: pureCipherData // 🌟 核心修复 3：送入硬件解密的只剩纯密文，不能包含 Tag
    };

    try {
      let session = await huks.initSession(CryptoUtil.keyAlias, options);
      let result = await huks.finishSession(session.handle, options);

      if (!result.outData) {
        throw new Error("HUKS 解密未返回有效载荷");
      }
      return new util.TextDecoder().decodeToString(result.outData);

    } catch (error) {
      hilog.error(0x0000, 'CryptoUtil', 'HUKS硬件防篡改拦截(Tag校验不通过)');
      return "";
    }
  }
}