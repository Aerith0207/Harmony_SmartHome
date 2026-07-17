// frontend/entry/src/main/ets/core/utils/CryptoUtil.ets
import cryptoFramework from '@ohos.security.cryptoFramework';
import huks from '@ohos.security.huks';
import util from '@ohos.util';
import hilog from '@ohos.hilog';

export class CryptoUtil {
  static readonly keyAlias: string = 'SmartHome_AES_Key_V1';

  // 🌟 严格对齐硬件文档：16字节固定密钥 (AES-128)
  private static readonly KEY_BYTES = new Uint8Array([
    0x2B, 0x7E, 0x15, 0x16, 0x28, 0xAE, 0xD2, 0xA6,
    0xAB, 0xF7, 0x15, 0x88, 0x09, 0xCF, 0x4F, 0x3C
  ]);

  // 🌟 严格对齐硬件文档：12字节固定 Nonce (IV)
  private static readonly IV_BYTES = new Uint8Array([
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
    0x08, 0x09, 0x0A, 0x0B
  ]);

  /**
   * 🌟 核心新增：初始化密钥层保护，将明文密钥导入底层 TEE 安全区托管
   */
  public static async initKeyStore(): Promise<void> {
    let properties: Array<huks.HuksParam> = [
      { tag: huks.HuksTag.HUKS_TAG_ALGORITHM, value: huks.HuksKeyAlg.HUKS_ALG_AES },
      { tag: huks.HuksTag.HUKS_TAG_PURPOSE, value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT | huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT },
      { tag: huks.HuksTag.HUKS_TAG_KEY_SIZE, value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_128 },
      { tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE, value: huks.HuksCipherMode.HUKS_MODE_GCM },
      { tag: huks.HuksTag.HUKS_TAG_PADDING, value: huks.HuksKeyPadding.HUKS_PADDING_NONE }
    ];

    try {
      let isExist = false;
      try {
        // 🌟 修复：将 this.keyAlias 替换为 CryptoUtil.keyAlias
        await huks.hasKeyItem(CryptoUtil.keyAlias, { properties: properties });
        isExist = true;
      } catch (e) {
        isExist = false;
      }

      if (!isExist) {
        // 🌟 修复：将 this.keyAlias 替换为 CryptoUtil.keyAlias
        let options: huks.HuksOptions = { properties: properties, inData: CryptoUtil.KEY_BYTES };
        await huks.importKeyItem(CryptoUtil.keyAlias, options);
        hilog.info(0x0000, 'HUKS_STORE', '✅ AES核心密钥已成功导入并托管至鸿蒙底层TEE安全环境');
      } else {
        hilog.info(0x0000, 'HUKS_STORE', '✅ TEE安全区已存在托管密钥，跳过导入');
      }
    } catch (error) {
      hilog.error(0x0000, 'HUKS_STORE', `❌ 密钥硬件级托管失败: ${JSON.stringify(error)}`);
    }
  }

  private static async getSymKey(): Promise<cryptoFramework.SymKey> {
    try {
      let symKeyGenerator = cryptoFramework.createSymKeyGenerator('AES128');
      return await symKeyGenerator.convertKey({ data: CryptoUtil.KEY_BYTES });
    } catch (error) {
      throw new Error("生成对称密钥对象失败");
    }
  }

  public static async encrypt(plainText: string): Promise<Uint8Array> {
    try {
      let symKey = await CryptoUtil.getSymKey();
      let cipher = cryptoFramework.createCipher('AES128|GCM|PKCS7');
      let gcmParams: cryptoFramework.GcmParamsSpec = {
        iv: { data: CryptoUtil.IV_BYTES },
        aad: { data: new Uint8Array(0) },
        authTag: { data: new Uint8Array(0) },
        algName: 'GcmParamsSpec'
      };
      await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, symKey, gcmParams);
      let plainBlob: cryptoFramework.DataBlob = { data: new util.TextEncoder().encodeInto(plainText) };
      let cipherBlob = await cipher.doFinal(plainBlob);
      return cipherBlob.data;
    } catch (error) {
      let e = error as Error;
      hilog.error(0x0000, 'CryptoUtil', `加密彻底失败: ${e.message}`);
      throw new Error(e.message);
    }
  }

  public static async decrypt(cipherWithTag: Uint8Array): Promise<string> {
    try {
      if (cipherWithTag.length <= 16) {
        throw new Error("报文长度不足，缺少Tag");
      }
      let tagData = cipherWithTag.slice(cipherWithTag.length - 16);
      let pureCipherData = cipherWithTag.slice(0, cipherWithTag.length - 16);
      let symKey = await CryptoUtil.getSymKey();
      let decoder = cryptoFramework.createCipher('AES128|GCM|PKCS7');
      let gcmParams: cryptoFramework.GcmParamsSpec = {
        iv: { data: CryptoUtil.IV_BYTES },
        aad: { data: new Uint8Array(0) },
        authTag: { data: tagData },
        algName: 'GcmParamsSpec'
      };
      await decoder.init(cryptoFramework.CryptoMode.DECRYPT_MODE, symKey, gcmParams);
      let plainBlob = await decoder.doFinal({ data: pureCipherData });
      return new util.TextDecoder().decodeToString(plainBlob.data);
    } catch (error) {
      let e = error as Error;
      hilog.error(0x0000, 'CryptoUtil', `解密失败(Tag校验不通过或数据损坏): ${e.message}`);
      return "";
    }
  }
}